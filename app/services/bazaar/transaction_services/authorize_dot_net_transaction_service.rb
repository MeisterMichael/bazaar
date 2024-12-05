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

			SUCCESS_RESPONSE_CODES = ['1','ok','Ok']

			WHITELISTED_ERROR_MESSAGES = [ 'The credit card has expired' ]

			def initialize( args = {} )
				raise Exception.new('add "gem \'authorizenet\'" to your Gemfile') unless defined?( AuthorizeNet )

				@api_login	= args[:API_LOGIN_ID] || ENV['AUTHORIZE_DOT_NET_API_LOGIN_ID']
				@api_key	= args[:TRANSACTION_API_KEY] || ENV['AUTHORIZE_DOT_NET_TRANSACTION_API_KEY']
				@gateway	= ( args[:GATEWAY] || ENV['AUTHORIZE_DOT_NET_GATEWAY'] || :sandbox ).to_sym
				@enable_debug = not( Rails.env.production? ) || ENV['AUTHORIZE_DOT_NET_DEBUG'] == '1' || @gateway == :sandbox

				@transaction_provider  = args[:transaction_provider]
				raise Exception.new("TransactionProvider not found") unless @transaction_provider.present? || !Bazaar.require_transaction_providers
				@provider_name = args[:provider_name] || "#{PROVIDER_NAME}-#{@api_login}"
			end

			def capture_payment_method( order, args = {} )
				payment_details = extract_payment_details( args )

				self.calculate( order )
				return false if order.nested_errors.present?

				profiles = get_order_customer_profile( order, payment_details )
				return false if profiles == false

				order.payment_status = 'payment_method_captured'
				order.provider = @provider_name
				order.transaction_provider = self.transaction_provider
				order.merchant_identification = self.merchant_identification
				order.provider_customer_profile_reference = profiles[:customer_profile_reference]
				order.provider_customer_payment_profile_reference = profiles[:customer_payment_profile_reference]

				return order if order.save
				return false
			end

			def get_first_message_code( response )
				if response.respond_to?( :messages )
					response.messages.messages.collect(&:code).first
				else
					response.class.name
				end
			end

			def get_frist_message_text( response )
				if response.respond_to?( :messages )
					response.messages.messages.collect(&:text).first
				else
					response.to_s
				end
			end

			def get_response_success?( response )
				return false unless response.present?
				response.messages.resultCode == AuthorizeNet::API::MessageTypeEnum::Ok
			end

			def process( order, args = {} )
				payment_details = extract_payment_details( args )

				self.calculate( order )
				return false if order.nested_errors.present?

				profiles = get_order_customer_profile( order, payment_details )
				return false if profiles == false

				order.provider = @provider_name
				order.transaction_provider = self.transaction_provider
				order.merchant_identification = self.merchant_identification
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
					transaction_provider: self.transaction_provider,
					merchant_identification: self.merchant_identification,
					amount: order.total,
					currency: order.currency,
					status: 'declined',
				)

				transaction_properties = {}

				if payment_details.present?

					order.properties = order.properties.merge(payment_details[:meta_data])
					transaction_properties = payment_details[:meta_data]

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

				process_transaction( transaction, payment_details )

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

			def process_transaction( transaction, payment_details, args = {} )

				if credit_card_info.present? && transaction.parent_obj.present?

					profiles = get_order_customer_profile( transaction.parent_obj, payment_details )
					if profiles == false
						transaction.status = 'declined'
						transaction.message = "Unable to create customer profile"
						transaction.save
						return false
					end

					transaction.customer_profile_reference = profiles[:customer_profile_reference]
					transaction.customer_payment_profile_reference = profiles[:customer_payment_profile_reference]

				end

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
				if get_response_success?( response ) && SUCCESS_RESPONSE_CODES.include?( transaction_response.responseCode.to_s.downcase )

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

			def transaction_provider
				@transaction_provider
			end

			def merchant_identification
				@transaction_provider.try(:merchant_identification)
			end

			def refund( args = {} )
				# assumes :amount, and :charge_transaction
				charge_transaction	= args.delete( :charge_transaction )
				parent							= args.delete( :order ) || args.delete( :parent )
				anet_transaction_id	= args.delete( :transaction_id )
				amount							= args.delete( :amount )

				new_transactions = []

				if charge_transaction.present?

					new_transactions << refund_transaction( charge_transaction, args.merge( amount: amount ) )

				elsif anet_transaction_id.present?

					charge_transaction	= Bazaar::Transaction.charge.approved.where( provider: @provider_name, reference_code: anet_transaction_id ).first
					raise Exception.new( 'Unable to find transaction by reference code' ) if charge_transaction.nil?

					new_transactions << refund_transaction( charge_transaction, args.merge( amount: amount ) )

				elsif parent.present? && ( charge_transactions = Bazaar::Transaction.charge.approved.where(  provider: @provider_name, parent_obj: parent ) ).count >= 1

					refund_transactions = Bazaar::Transaction.refund.approved.where( provider: @provider_name, parent_obj: parent )
					refunded_amount = refund_transactions.sum(:amount)
					charged_amount = charge_transactions.sum(:amount)

					remaining_refund_amount = amount || ( charged_amount - refunded_amount )


					raise Exception.new( "Refund amount is more than the sum of charges" ) if remaining_refund_amount > (charged_amount - refunded_amount)

					# iterate over transactions to find those that have capacity to accept
					# refunds, and apply the refund amount to them until none is left
					running_charge_total = 0
					charge_transactions.order( created_at: :asc ).each do |charge_transaction|

						running_charge_total += charge_transaction.amount
						transaction_max_refund_amount = running_charge_total - refunded_amount

						# if the total charges at this point is more than the amount already
						# refunded then this transaction has room for additional refunds.
						if transaction_max_refund_amount > 0
							# The amount that can be refunded on this charge.
							transaction_refund_amount = [transaction_max_refund_amount,remaining_refund_amount].min

							new_transactions << refund_transaction( charge_transaction, args.merge( amount: transaction_refund_amount ) )

							refunded_amount += transaction_refund_amount
							remaining_refund_amount -= transaction_refund_amount
						end

						break if remaining_refund_amount == 0

					end

				else
					raise Exception.new( 'Unable to refund, unable to find transactions.' )
				end

				new_transactions

			end

			def refund_transaction( charge_transaction, args = {} )
				raise Exception.new( "charge_transaction must be an approved charge." ) unless charge_transaction.charge? && charge_transaction.approved?

				args[:amount] ||= charge_transaction.amount

				transaction = Bazaar::Transaction.new( args )
				transaction.transaction_type	= 'refund'
				transaction.provider					= @provider_name
				transaction.transaction_provider = self.transaction_provider
				transaction.merchant_identification = self.merchant_identification
				transaction.currency					||= charge_transaction.currency
				transaction.parent_obj				||= charge_transaction.parent_obj

				transaction.customer_profile_reference ||= charge_transaction.customer_profile_reference
				transaction.customer_payment_profile_reference ||= charge_transaction.customer_payment_profile_reference

				transaction.properties					= charge_transaction.properties.merge( transaction.properties ) if charge_transaction
				transaction.credit_card_ending_in		= charge_transaction.credit_card_ending_in if charge_transaction.respond_to?(:credit_card_ending_in)
				transaction.credit_card_brand			= charge_transaction.credit_card_brand if charge_transaction.respond_to?(:credit_card_brand)
				transaction.billing_address				= charge_transaction.billing_address if charge_transaction.respond_to?(:billing_address)

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
				request.transactionRequest.refTransId = charge_transaction.reference_code
				request.transactionRequest.transactionType = AuthorizeNet::API::TransactionTypeEnum::RefundTransaction

				response = anet_transaction.create_transaction( request )
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
						request.transactionRequest.refTransId = charge_transaction.reference_code
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
						# request.transactionRequest.refTransId = charge_transaction.reference_code
						request.transactionRequest.transactionType = AuthorizeNet::API::TransactionTypeEnum::RefundTransaction

						response = anet_transaction.create_transaction( request )

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

				else
					puts response.to_xml if @enable_debug

					NewRelic::Agent.notice_error(Exception.new( "Authorize.net Transaction Error: #{get_first_message_code( response )} - #{get_frist_message_text( response )}" )) if defined?( NewRelic )

					transaction.status = 'declined'
					transaction.message = get_frist_message_text( response )
					transaction.message = "#{transaction.message} -> #{transaction_response.errors.errors[0].errorText}" if transaction_response.present? && transaction_response.errors.present?

					transaction.save

				end

				transaction
			end

			def update_subscription_payment_profile( subscription, args = {} )

				payment_details = extract_payment_details( args )

				payment_profile = request_payment_profile( subscription.user, subscription.billing_address, payment_details, errors: subscription.errors, ip: subscription.order.try(:ip) )

				return false unless payment_profile

				subscription.provider = @provider_name
				subscription.transaction_provider = self.transaction_provider
				subscription.merchant_identification = self.merchant_identification
				subscription.provider_customer_profile_reference = payment_profile[:customer_profile_reference]
				subscription.provider_customer_payment_profile_reference = payment_profile[:customer_payment_profile_reference]
				subscription.properties = subscription.properties.merge( payment_details[:meta_data] )
				subscription.payment_profile_expires_at	= payment_details[:expires_at] if subscription.respond_to?(:payment_profile_expires_at)

				subscription.save

			end

			protected

			def extract_payment_details( args = {} )
				payment_details = { error: 'invalid payment details' }

				if args[:credit_card].present?

					card_number = args[:credit_card][:card_number]
					expiration_str = args[:credit_card][:expiration]
					card_code = args[:credit_card][:card_code]

					credit_card_dector = CreditCardValidations::Detector.new( card_number )

					expires_at = Bazaar::TransactionService.parse_credit_card_expiry( expiration_str )

					meta_data = {
						'credit_card_ending_in' => credit_card_dector.number[-4,4],
						'credit_card_brand' => credit_card_dector.brand,
					}

					details = {
						card_number: card_number,
						expiration: expiration_str,
						card_code: card_code,
					}

					payment_details = {
						type: 'credit_card',
						meta_data: meta_data,
						details: details,
						expires_at: expires_at,
					}

					if expires_at < Time.now
						payment_details[:error] = 'Credit Card is Expired'
					elsif not( credit_card_dector.valid? )
						payment_details[:error] = 'Invalid Credit Card Number'
					end

				elsif args[:google_pay].present?

					payment_data = JSON.parse(args.dig(:google_pay,:payment_data) || '{}', :symbolize_names => true )
					payment_token = payment_data.dig(:paymentMethodData,:tokenizationData,:token)
					payment_token_type = payment_data.dig(:paymentMethodData,:tokenizationData,:type)

					meta_data = {
						'credit_card_ending_in' => payment_data.dig(:paymentMethodData,:info,:cardDetails),
						'credit_card_brand' => payment_data.dig(:paymentMethodData,:info,:cardNetwork),
					}

					details = {
						token: payment_token,
						token_type: payment_token_type,
						results: args[:google_pay],
					}

					payment_details = {
						type: 'google_pay',
						meta_data: meta_data,
						details: details,
					}

					if payment_token.blank?
						payment_details[:error] = 'Invalid Google Pay Token'
					end
				else

					raise Exception.new("Unable to extract payment details")
				end

				payment_details
			end

			def get_order_customer_profile( order, payment_details, args = {} )

				if payment_details[:error].blank?

					payment_profile = request_payment_profile( order.user, order.billing_address, payment_details, email: order.email, errors: order.errors, ip: order.ip )

					return payment_profile if payment_profile && order.nested_errors.blank?

				else
					return { customer_profile_reference: order.provider_customer_profile_reference, customer_payment_profile_reference: order.provider_customer_payment_profile_reference } if order.provider_customer_profile_reference.present?

					raise Exception.new( 'cannot create payment profile without valid payment info' )

				end

				return false
			end


			def request_payment_profile( user, billing_address, payment_details, args={} )
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

				# report any errors with the payment details
				if payment_details[:error].present?
					errors.add( :base, payment_details[:error] ) if errors
					return false
				end


				if payment_details[:type] == 'credit_card'

					# VALIDATE Credit card expirey
					if payment_details[:expires_at].nil?
						errors.add( :base, 'Credit Card Expired is required') if errors
						return false
					elsif payment_details[:expires_at].end_of_month < Time.now.end_of_month
						errors.add( :base, 'Credit Card has Expired') if errors
						return false
					end

					formatted_expiration = payment_details[:details][:expiration].gsub( /\/\s*\d\d(\d\d)/, '/\\1' ).gsub(/\s*\/\s*/,'')
					formatted_number = payment_details[:details][:card_number].gsub(/\s/,'')
					
					anet_payment = AuthorizeNet::API::PaymentType.new(AuthorizeNet::API::CreditCardType.new)
					anet_payment.creditCard.cardNumber = formatted_number
					anet_payment.creditCard.expirationDate = formatted_expiration
					anet_payment.creditCard.cardCode = payment_details[:details][:card_code]

					anet_payment_profile = AuthorizeNet::API::CustomerPaymentProfileType.new
					anet_payment_profile.payment	= anet_payment
					anet_payment_profile.billTo		= anet_billing_address

				elsif payment_details[:type] == 'google_pay'

					anet_payment = AuthorizeNet::API::PaymentType.new(AuthorizeNet::API::OpaqueDataType.new)
					anet_payment.creditCard = nil
					anet_payment.opaqueData = AuthorizeNet::API::OpaqueDataType.new
					anet_payment.opaqueData.dataDescriptor = 'COMMON.GOOGLE.INAPP.PAYMENT'
					# anet_payment.opaqueData.dataValue = payment_details[:details][:token]
					anet_payment.opaqueData.dataValue = Base64.strict_encode64(payment_details[:details][:token])

					anet_payment_profile = AuthorizeNet::API::CustomerPaymentProfileType.new
					anet_payment_profile.payment	= anet_payment

				end

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
