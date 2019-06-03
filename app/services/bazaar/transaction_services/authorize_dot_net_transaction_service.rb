# require 'authorizenet'
require 'credit_card_validations'

module Bazaar

	module TransactionServices

		class AuthorizeDotNetTransactionService < Bazaar::TransactionService

			PROVIDER_NAME = 'Authorize.net'
			ERROR_DUPLICATE_CUSTOMER_PROFILE = 'E00039'
			ERROR_DUPLICATE_CUSTOMER_PAYMENT_PROFILE = 'E00039'
			ERROR_INVALID_PAYMENT_PROFILE = 'E00003'
			CANNOT_REFUND_CHARGE = 'E00027'

			WHITELISTED_ERROR_MESSAGES = [ 'The credit card has expired' ]

			def initialize( args = {} )
				raise Exception.new('add "gem \'authorizenet\'" to your Gemfile') unless defined?( AuthorizeNet )

				@api_login	= args[:API_LOGIN_ID] || ENV['AUTHORIZE_DOT_NET_API_LOGIN_ID']
				@api_key	= args[:TRANSACTION_API_KEY] || ENV['AUTHORIZE_DOT_NET_TRANSACTION_API_KEY']
				@gateway	= ( args[:GATEWAY] || ENV['AUTHORIZE_DOT_NET_GATEWAY'] || :sandbox ).to_sym
				@enable_debug = not( Rails.env.production? ) || ENV['AUTHORIZE_DOT_NET_DEBUG'] == '1' || @gateway == :sandbox
				@provider_name = args[:provider_name] || "#{PROVIDER_NAME}-#{@api_login}"
			end

			def capture_payment_method( order, args = {} )
				credit_card_info = args[:credit_card]

				self.calculate( order )
				return false if order.nested_errors.present?

				profiles = get_order_customer_profile( order, credit_card: credit_card_info )
				return false if profiles == false

				order.payment_status = 'payment_method_captured'
				order.provider = @provider_name
				order.provider_customer_profile_reference = profiles[:customer_profile_reference]
				order.provider_customer_payment_profile_reference = profiles[:customer_payment_profile_reference]

				return order if order.save
				return false
			end

			def get_first_message_code( response )
				response.messages.messages.collect(&:code).first
			end

			def get_frist_message_text( response )
				response.messages.messages.collect(&:text).first
			end

			def get_response_success?( response )
				return false unless response.present?
				response.messages.resultCode == AuthorizeNet::API::MessageTypeEnum::Ok
			end

			def process( order, args = {} )
				credit_card_info = args[:credit_card]

				self.calculate( order )
				return false if order.nested_errors.present?

				profiles = get_order_customer_profile( order, credit_card: credit_card_info )
				return false if profiles == false

				order.provider = @provider_name
				order.provider_customer_profile_reference = profiles[:customer_profile_reference]
				order.provider_customer_payment_profile_reference = profiles[:customer_payment_profile_reference]
				order.save

				transaction = Bazaar::Transaction.new(
					billing_address: order.billing_address,
					parent_obj: order,
					transaction_type: 'charge',
					customer_profile_reference: profiles[:customer_profile_reference],
					customer_payment_profile_reference: profiles[:customer_payment_profile_reference],
					provider: @provider_name,
					amount: order.total,
					currency: order.currency,
					status: 'declined',
				)

				transaction_properties = {}

				if credit_card_info.present? && credit_card_info[:card_number].present?
					credit_card_dector = CreditCardValidations::Detector.new( credit_card_info[:card_number] )

					new_properties = {
						'credit_card_ending_in' => credit_card_dector.number[-4,4],
						'credit_card_brand' => credit_card_dector.brand,
					}

					order.properties = order.properties.merge(new_properties)
					transaction_properties = new_properties

				elsif ( first_profile_transaction = Bazaar::Transaction.where( provider: @provider_name, customer_profile_reference: profiles[:customer_profile_reference], customer_payment_profile_reference: profiles[:customer_payment_profile_reference] ).where.not(credit_card_ending_in: nil).first ).present?

					new_properties = {
						'credit_card_ending_in' => first_profile_transaction.credit_card_ending_in,
						'credit_card_brand' => first_profile_transaction.credit_card_brand,
					}

					order.properties = order.properties.merge(new_properties)
					transaction_properties = new_properties

				end

				# add transaction_properties as attributes if available, otherwise as properties
				transaction_properties.each do |attribute,value|
					if transaction.respond_to?("#{attribute}=")
						transaction.method( "#{attribute}=").call(value)
					else
						transaction.properties[attribute] = value
					end
				end

				transaction.save

				process_transaction( transaction )

				# process response
				if transaction.approved?

					# if capture is successful, save order, and create transaction.
					order.payment_status = 'paid'

					if order.save

						# sanity check
						raise Exception.new( "Bazaar::Transaction create errors #{transaction.errors.full_messages}" ) if transaction.errors.present?

						return transaction

					end

				else

					puts response.to_xml if @enable_debug

					order.status = 'failed'
					order.payment_status = 'declined'
					order.save

					if WHITELISTED_ERROR_MESSAGES.include? transaction.message
						order.errors.add(:base, :processing_error, message: transaction.message )
					else
						order.errors.add(:base, :processing_error, message: "Transaction declined.")
					end


					return transaction
				end


				return false
			end

			def process_transaction( transaction, args = {} )

				anet_transaction = AuthorizeNet::API::Transaction.new(@api_login, @api_key, :gateway => @gateway )

				request = AuthorizeNet::API::CreateTransactionRequest.new
				request.transactionRequest = AuthorizeNet::API::TransactionRequestType.new()
				request.transactionRequest.amount = transaction.amount_as_money
				request.transactionRequest.transactionType = AuthorizeNet::API::TransactionTypeEnum::AuthCaptureTransaction
				request.transactionRequest.order = AuthorizeNet::API::OrderType.new(transaction.parent_obj.code) if transaction.parent_obj.is_a? Bazaar::Order
				request.transactionRequest.profile = AuthorizeNet::API::CustomerProfilePaymentType.new
				request.transactionRequest.profile.customerProfileId = transaction.customer_profile_reference
				request.transactionRequest.profile.paymentProfile = AuthorizeNet::API::PaymentProfile.new(transaction.customer_payment_profile_reference)

				response = anet_transaction.create_transaction(request)

				transaction_response = response.transactionResponse

				transaction.reference_code = transaction_response.try(:transId)

				puts response.to_xml if @enable_debug

				# process response
				if get_response_success?( response ) && ['1','Ok'].include?( transaction_response.responseCode.to_s )

					transaction.status = 'approved'
					transaction.save

				else

					transaction.status = 'declined'
					transaction.message = get_frist_message_text( response )
					transaction.properties['response_message'] = transaction.message
					transaction.message = "#{transaction.message} -> #{transaction_response.errors.errors[0].errorText}" if transaction_response.present? && transaction_response.errors.present?
					transaction.save

				end

				return transaction.approved?
			end

			def provider_name
				@provider_name
			end

			def refund( args = {} )
				# assumes :amount, and :charge_transaction
				charge_transaction	= args.delete( :charge_transaction )
				parent				= args.delete( :order ) || args.delete( :parent )
				charge_transaction	||= Transaction.where( parent_obj: parent ).charge.first if parent.present?
				anet_transaction_id = args.delete( :transaction_id )

				raise Exception.new( "charge_transaction must be an approved charge." ) unless charge_transaction.nil? || ( charge_transaction.charge? && charge_transaction.approved? )

				transaction = Bazaar::Transaction.new( args )
				transaction.transaction_type	= 'refund'
				transaction.provider					= @provider_name

				if charge_transaction.present?

					transaction.currency			||= charge_transaction.currency
					transaction.parent_obj			||= charge_transaction.parent_obj

					transaction.customer_profile_reference ||= charge_transaction.customer_profile_reference
					transaction.customer_payment_profile_reference ||= charge_transaction.customer_payment_profile_reference

					transaction.amount = charge_transaction.amount unless args[:amount].present?

					anet_transaction_id ||= charge_transaction.reference_code

				elsif anet_transaction_id.present?

					charge_transaction = Bazaar::Transaction.charge.approved.find_by( provider: @provider_name, reference_code: anet_transaction_id )

				end

				transaction.properties	= charge_transaction.properties.merge( transaction.properties ) if charge_transaction
				transaction.credit_card_ending_in = charge_transaction.credit_card_ending_in if charge_transaction.respond_to?(:credit_card_ending_in)
				transaction.credit_card_brand = charge_transaction.credit_card_brand if charge_transaction.respond_to?(:credit_card_brand)
				transaction.billing_address = charge_transaction.billing_address if charge_transaction.respond_to?(:billing_address)

				raise Exception.new('unable to find transaction') if anet_transaction_id.nil?

				if transaction.amount <= 0
					transaction.status = 'declined'
					transaction.errors.add(:base, "Refund amount must be greater than 0")
					return transaction
				end

				# convert cents to dollars
				refund_dollar_amount = transaction.amount / 100.0

				anet_transaction = AuthorizeNet::API::Transaction.new(@api_login, @api_key, :gateway => @gateway )

				request = AuthorizeNet::API::CreateTransactionRequest.new
				request.transactionRequest = AuthorizeNet::API::TransactionRequestType.new()
				request.transactionRequest.amount = refund_dollar_amount
				request.transactionRequest.profile = AuthorizeNet::API::CustomerProfilePaymentType.new
				request.transactionRequest.profile.customerProfileId = transaction.customer_profile_reference
				request.transactionRequest.profile.paymentProfile = AuthorizeNet::API::PaymentProfile.new(transaction.customer_payment_profile_reference)
				# request.transactionRequest.payment = AuthorizeNet::API::PaymentType.new
				# request.transactionRequest.payment.creditCard = CreditCardType.new('0015','XXXX')
				request.transactionRequest.refTransId = anet_transaction_id
				request.transactionRequest.transactionType = AuthorizeNet::API::TransactionTypeEnum::RefundTransaction

				response = anet_transaction.create_transaction( request )

				# response = anet_transaction.create_transaction_refund(
				# 	anet_transaction_id,
				# 	refund_dollar_amount,
				# 	transaction.customer_profile_reference,
				# 	transaction.customer_payment_profile_reference
				# )

				puts response.to_xml if @enable_debug

				if get_first_message_code( response ) == CANNOT_REFUND_CHARGE
					# if you cannot refund it, that means the origonal charge
					# hasn't been settled yet, so you...

					if transaction.amount == charge_transaction.amount
						# have to void (but only if the refund is for the total amount)
						transaction.transaction_type = 'void'
						anet_transaction = AuthorizeNet::API::Transaction.new(@api_login, @api_key, :gateway => @gateway )


						request = AuthorizeNet::API::CreateTransactionRequest.new
						request.transactionRequest = AuthorizeNet::API::TransactionRequestType.new()
						request.transactionRequest.refTransId = anet_transaction_id
						request.transactionRequest.transactionType = AuthorizeNet::API::TransactionTypeEnum::VoidTransaction

						response = anet_transaction.create_transaction(request)

						puts response.to_xml if @enable_debug
					else
						# OR create a refund that is unlinked to the transaction
						anet_transaction = AuthorizeNet::API::Transaction.new(@api_login, @api_key, :gateway => @gateway )


						request = AuthorizeNet::API::CreateTransactionRequest.new
						request.transactionRequest = AuthorizeNet::API::TransactionRequestType.new()
						request.transactionRequest.amount = refund_dollar_amount
						request.transactionRequest.profile = AuthorizeNet::API::CustomerProfilePaymentType.new
						request.transactionRequest.profile.customerProfileId = transaction.customer_profile_reference
						request.transactionRequest.profile.paymentProfile = AuthorizeNet::API::PaymentProfile.new(transaction.customer_payment_profile_reference)
						# request.transactionRequest.payment = AuthorizeNet::API::PaymentType.new
						# request.transactionRequest.payment.creditCard = CreditCardType.new('0015','XXXX')
						# request.transactionRequest.refTransId = anet_transaction_id
						request.transactionRequest.transactionType = AuthorizeNet::API::TransactionTypeEnum::RefundTransaction

						response = anet_transaction.create_transaction( request )



						# anet_transaction.set_fields(:trans_id => nil)
						# anet_transaction.create_transaction(
						# 	:refund,
						# 	refund_dollar_amount,
						# 	transaction.customer_profile_reference,
						# 	transaction.customer_payment_profile_reference,
						# 	nil, #order
						# 	{}, #options
						# )

						# response = anet_transaction.create_transaction_refund(
						# 	nil,
						# 	refund_dollar_amount,
						# 	transaction.customer_profile_reference,
						# 	transaction.customer_payment_profile_reference
						# )

					end
				end

				transaction_response = response.transactionResponse

				# process response
				if get_response_success?( response ) && ['1','Ok'].include?( transaction_response.responseCode.to_s )

					transaction.status = 'approved'
					transaction.reference_code = transaction_response.try(:transId)

					# if capture is successful, create transaction.
					transaction.save

					# update corresponding order to a payment status of refunded
					transaction.parent_obj.update payment_status: 'refunded'

					# sanity check
					# raise Exception.new( "Bazaar::Transaction create errors #{transaction.errors.full_messages}" ) if transaction.errors.present?
				else
					puts response.to_xml if @enable_debug

					NewRelic::Agent.notice_error(Exception.new( "Authorize.net Transaction Error: #{get_first_message_code( response )} - #{get_frist_message_text( response )}" )) if defined?( NewRelic )

					transaction.status = 'declined'
					transaction.message = get_frist_message_text( response )
					transaction.message = "#{transaction.message} -> #{transaction_response.errors.errors[0].errorText}" if transaction_response.present? && transaction_response.errors.present?

					transaction.save

					# sanity check
					# raise Exception.new( "Bazaar::Transaction create errors #{transaction.errors.full_messages}" ) if transaction.errors.present?

				end

				transaction
			end

			def update_subscription_payment_profile( subscription, args = {} )
				payment_profile = request_payment_profile( subscription.user, subscription.billing_address, args[:credit_card], errors: subscription.errors, ip: subscription.order.try(:ip) )

				return false unless payment_profile

				credit_card_dector = CreditCardValidations::Detector.new( args[:credit_card][:card_number] )

				new_properties = {
					'credit_card_ending_in' => credit_card_dector.number[-4,4],
					'credit_card_brand' => credit_card_dector.brand,
				}

				subscription.provider = @provider_name
				subscription.provider_customer_profile_reference = payment_profile[:customer_profile_reference]
				subscription.provider_customer_payment_profile_reference = payment_profile[:customer_payment_profile_reference]
				subscription.properties = subscription.properties.merge( new_properties )
				subscription.payment_profile_expires_at	= Bazaar::TransactionService.parse_credit_card_expiry( args[:credit_card][:expiration] ) if subscription.respond_to?(:payment_profile_expires_at)

				subscription.save

			end

			protected

			def get_order_customer_profile( order, args = {} )

				if args[:credit_card].present?

					payment_profile = request_payment_profile( order.user, order.billing_address, args[:credit_card], email: order.email, errors: order.errors, ip: order.ip )

					return payment_profile if payment_profile && order.nested_errors.blank?

				else
					return { customer_profile_reference: order.provider_customer_profile_reference, customer_payment_profile_reference: order.provider_customer_payment_profile_reference } if order.provider_customer_profile_reference.present?

					raise Exception.new( 'cannot create payment profile without credit card info' )

				end

				return false
			end


			def request_payment_profile( user, billing_address, credit_card, args={} )
				anet_transaction = AuthorizeNet::API::Transaction.new(@api_login, @api_key, :gateway => @gateway )
				errors = args[:errors]

				ip_address = args[:ip] if args[:ip].present?
				ip_address ||= user.try(:ip) if user.try(:ip).present?

				billing_address_state = billing_address.state
				billing_address_state = billing_address.geo_state.try(:abbrev) if billing_address_state.blank?
				billing_address_state = billing_address.geo_state.try(:name) if billing_address_state.blank?

				street_address = billing_address.street
				street_address = "#{street_address}\n#{billing_address.street2}" if billing_address.street2.present?

				anet_billing_address = AuthorizeNet::API::CustomerAddressType.new
				anet_billing_address.firstName		= billing_address.first_name
				anet_billing_address.lastName			= billing_address.last_name
				# anet_billing_address.company		= nil
				anet_billing_address.address			= street_address
				anet_billing_address.city					= billing_address.city
				anet_billing_address.state				= billing_address_state
				anet_billing_address.zip					= billing_address.zip
				anet_billing_address.country			= billing_address.geo_country.name
				anet_billing_address.phoneNumber	= billing_address.phone

				# VALIDATE Credit card number
				credit_card_dector = CreditCardValidations::Detector.new(credit_card[:card_number])
				unless credit_card_dector.valid?
					errors.add( :base, 'Invalid Credit Card Number' ) if errors
					return false
				end

				# VALIDATE Credit card expirey
				expiration_time = Bazaar::TransactionService.parse_credit_card_expiry( credit_card[:expiration] )
				if expiration_time.nil?
					errors.add( :base, 'Credit Card Expired is required') if errors
					return false
				elsif expiration_time.end_of_month < Time.now.end_of_month
					errors.add( :base, 'Credit Card has Expired') if errors
					return false
				end

				formatted_expiration = credit_card[:expiration].gsub(/\s*\/\s*/,'')
				formatted_number = credit_card[:card_number].gsub(/\s/,'')

				anet_credit_card = AuthorizeNet::API::PaymentType.new(AuthorizeNet::API::CreditCardType.new)
				anet_credit_card.creditCard.cardNumber = formatted_number
				anet_credit_card.creditCard.expirationDate = formatted_expiration
				anet_credit_card.creditCard.cardCode = credit_card[:card_code]

				anet_payment_profile = AuthorizeNet::API::CustomerPaymentProfileType.new
				anet_payment_profile.payment	= anet_credit_card
				anet_payment_profile.billTo		= anet_billing_address
				# anet_payment_profile.defaultPaymentProfile = true

				# anet_customer_profile = AuthorizeNet::API::CustomerProfile.new(
				# 	:email			=> args[:email] || user.try(:email),
				# 	:id				=> user.try(:id),
				# 	:phone			=> billing_address.phone,
				# 	:address		=> anet_billing_address,
				# 	:description	=> "#{anet_billing_address.first_name} #{anet_billing_address.last_name}",
				# 	:ip				=> ip_address,
				# )
				# anet_customer_profile.payment_profiles = anet_payment_profile


				# Build the request object
				request = AuthorizeNet::API::CreateCustomerProfileRequest.new
				# Build the profile object containing the main information about the customer profile
				request.profile = AuthorizeNet::API::CustomerProfileType.new
				request.profile.merchantCustomerId = user.try(:id)
				request.profile.description = "#{anet_billing_address.firstName} #{anet_billing_address.lastName}"
				request.profile.email = (args[:email] || user.try(:email))
				# Add the payment profile and shipping profile defined previously
				request.profile.paymentProfiles = [anet_payment_profile]
				# request.profile.shipToList = [shippingAddress]
				request.validationMode = AuthorizeNet::API::ValidationModeEnum::LiveMode

				puts "request #{request.to_xml}"

				response = anet_transaction.create_customer_profile(request)
				# puts "request.profile.email #{request.profile.email}"
				# puts response.methods.to_json
				# puts "response.to_xml #{response.to_xml}"
				# puts "get_frist_message_text( response ) #{get_frist_message_text( response )}"
				# puts "get_first_message_code( response ) #{get_first_message_code( response )}"
				# puts "get_response_success?( response ) #{get_response_success?( response )}"

				# recover a customer profile if it already exists.
				if get_first_message_code( response ) == ERROR_DUPLICATE_CUSTOMER_PROFILE
					puts response.to_xml if @enable_debug

					anet_transaction = AuthorizeNet::API::Transaction.new(@api_login, @api_key, :gateway => @gateway )


					profile_id = get_frist_message_text( response ).match( /(\d{4,})/)[1]

					request = AuthorizeNet::API::GetCustomerProfileRequest.new
					request.customerProfileId = profile_id.to_s
					response = anet_transaction.get_customer_profile( request )

					profile = response.profile
					customer_profile_id = profile_id.to_s

					# create a new payment profile for existing customer
					anet_transaction = AuthorizeNet::API::Transaction.new(@api_login, @api_key, :gateway => @gateway )

					request = AuthorizeNet::API::CreateCustomerPaymentProfileRequest.new
					request.customerProfileId = customer_profile_id
					request.paymentProfile = anet_payment_profile


					response = anet_transaction.create_customer_payment_profile( request )
					puts response.to_xml if @enable_debug
					customer_payment_profile_id = response.customerPaymentProfileId

					if not( get_response_success?( response ) ) && get_first_message_code( response ) == ERROR_DUPLICATE_CUSTOMER_PAYMENT_PROFILE
						anet_payment_profile = AuthorizeNet::API::CustomerPaymentProfileExType.new
						anet_payment_profile.customerPaymentProfileId = customer_payment_profile_id
						anet_payment_profile.payment	= anet_credit_card
						anet_payment_profile.billTo		= anet_billing_address

						anet_transaction = AuthorizeNet::API::Transaction.new(@api_login, @api_key, :gateway => @gateway )

						request = AuthorizeNet::API::UpdateCustomerPaymentProfileRequest.new
						request.customerProfileId = customer_profile_id
						request.paymentProfile = anet_payment_profile

						response = anet_transaction.update_customer_payment_profile( request )
						puts response.to_xml if @enable_debug

					end


					return { customer_profile_reference: customer_profile_id, customer_payment_profile_reference: customer_payment_profile_id }

				elsif get_response_success?( response )

					customer_payment_profile_id = response.customerPaymentProfileIdList.numericString.first
					customer_profile_id = response.customerProfileId

					return { customer_profile_reference: customer_profile_id, customer_payment_profile_reference: customer_payment_profile_id }

				else

					puts response.to_xml if @enable_debug

					log_event( user: user, name: 'transaction_failed', content: "Authorize.net (#{@provider_name}) Payment Profile Error: #{get_first_message_code( response )} - #{get_frist_message_text( response )}" )

					if get_first_message_code( response ) == ERROR_INVALID_PAYMENT_PROFILE
						errors.add( :base, 'Invalid Payment Information') unless errors.nil?
					else
						errors.add( :base, 'We are unable to process your transaction.  Please verify your address, payment information and try again.') unless errors.nil?
					end

				end

				return false

			end


		end

	end

end
