require 'authorizenet'
require 'credit_card_validations'

module SwellEcom

	module TransactionServices

		class AuthorizeDotNetTransactionService < SwellEcom::TransactionService

			PROVIDER_NAME = 'Authorize.net'
			ERROR_DUPLICATE_CUSTOMER_PROFILE = 'E00039'
			ERROR_INVALID_PAYMENT_PROFILE = 'E00003'
			CANNOT_REFUND_CHARGE = 'E00027'

			WHITELISTED_ERROR_MESSAGES = [ 'The credit card has expired' ]

			def initialize( args = {} )
				@api_login	= args[:API_LOGIN_ID] || ENV['AUTHORIZE_DOT_NET_API_LOGIN_ID']
				@api_key	= args[:TRANSACTION_API_KEY] || ENV['AUTHORIZE_DOT_NET_TRANSACTION_API_KEY']
				@gateway	= ( args[:GATEWAY] || ENV['AUTHORIZE_DOT_NET_GATEWAY'] || :sandbox ).to_sym
				@enable_debug = not( Rails.env.production? ) || ENV['AUTHORIZE_DOT_NET_DEBUG'] == '1' || @gateway == :sandbox
			end

			def process( order, args = {} )
				credit_card_info = args[:credit_card]

				self.calculate( order )
				return false if order.errors.present?

				profiles = get_order_customer_profile( order, credit_card: credit_card_info )
				return false if profiles == false

				anet_order = nil

				# create capture
				anet_transaction = AuthorizeNet::CIM::Transaction.new(@api_login, @api_key, :gateway => @gateway )
				amount = order.total / 100.0 # convert cents to dollars
		        response = anet_transaction.create_transaction_auth_capture( amount, profiles[:customer_profile_reference], profiles[:customer_payment_profile_reference], anet_order )
				direct_response = response.direct_response


				# raise Exception.new("create auth capture error: #{response.message_text}") unless response.success?

				puts response.xml if @enable_debug

				# process response
				if response.success? && direct_response.success?

					# if capture is successful, save order, and create transaction.
					if order.save

						# update any subscriptions with profile ids
						order.order_items.each do |order_item|
							if order_item.subscription.present?
								order_item.subscription.provider = PROVIDER_NAME
								order_item.subscription.provider_customer_profile_reference = profiles[:customer_profile_reference]
								order_item.subscription.provider_customer_payment_profile_reference = profiles[:customer_payment_profile_reference]
								order_item.subscription.save
							end
						end

						transaction = SwellEcom::Transaction.create( parent_obj: order, transaction_type: 'charge', reference_code: direct_response.transaction_id, customer_profile_reference: profiles[:customer_profile_reference], customer_payment_profile_reference: profiles[:customer_payment_profile_reference], provider: PROVIDER_NAME, amount: order.total, currency: order.currency, status: 'approved' )

						if credit_card_info.present?

							credit_card_dector = CreditCardValidations::Detector.new( credit_card_info[:card_number] )

							new_properties = {
								'credit_card_ending_in' => credit_card_dector.number[-4,4],
								'credit_card_brand' => credit_card_dector.brand,
							}

							transaction.properties = transaction.properties.merge( new_properties ) if transaction.respond_to?( :properties )

							transaction.save

						end

						# sanity check
						raise Exception.new( "SwellEcom::Transaction create errors #{transaction.errors.full_messages}" ) if transaction.errors.present?

						return transaction

					end

				else

					puts response.xml if @enable_debug

					order.status = 'declined'

					transaction = false
					transaction = Transaction.create( transaction_type: 'charge', reference_code: direct_response.try(:transaction_id), customer_profile_reference: profiles[:customer_profile_reference], customer_payment_profile_reference: profiles[:customer_payment_profile_reference], provider: PROVIDER_NAME, amount: order.total, currency: order.currency, status: 'declined', message: response.message_text )

					if WHITELISTED_ERROR_MESSAGES.include? response.message_text
						order.errors.add(:base, :processing_error, message: response.message_text )
					else
						order.errors.add(:base, :processing_error, message: "Transaction declined.")
					end


					return transaction
				end


				return false
			end

			def refund( args = {} )
				# assumes :amount, and :charge_transaction
				charge_transaction	= args.delete( :charge_transaction )
				parent				= args.delete( :order ) || args.delete( :parent )
				charge_transaction	||= Transaction.where( parent_obj: parent ).charge.first if parent.present?
				anet_transaction_id = args.delete( :transaction_id )

				raise Exception.new( "charge_transaction must be an approved charge." ) unless charge_transaction.nil? || ( charge_transaction.charge? && charge_transaction.approved? )

				transaction = SwellEcom::Transaction.new( args )
				transaction.transaction_type	= 'refund'
				transaction.provider			= PROVIDER_NAME

				if charge_transaction.present?

					transaction.currency			||= charge_transaction.currency
					transaction.parent_obj			||= charge_transaction.parent_obj

					transaction.customer_profile_reference ||= charge_transaction.customer_profile_reference
					transaction.customer_payment_profile_reference ||= charge_transaction.customer_payment_profile_reference

					transaction.amount = charge_transaction.amount unless args[:amount].present?

					anet_transaction_id ||= charge_transaction.reference_code

				elsif anet_transaction_id.present?

					charge_transaction = SwellEcom::Transaction.charge.approved.find_by( provider: PROVIDER_NAME, reference_code: anet_transaction_id )

				end

				raise Exception.new('unable to find transaction') if anet_transaction_id.nil?

				if transaction.amount <= 0
					transaction.status = 'declined'
					transaction.errors.add(:base, "Refund amount must be greater than 0")
					return transaction
				end

				# convert cents to dollars
				refund_dollar_amount = transaction.amount / 100.0

				anet_transaction = AuthorizeNet::CIM::Transaction.new(@api_login, @api_key, :gateway => @gateway )
				response = anet_transaction.create_transaction_refund(
					anet_transaction_id,
					refund_dollar_amount,
					transaction.customer_profile_reference,
					transaction.customer_payment_profile_reference
				)

				puts response.xml if @enable_debug

				if response.message_code == CANNOT_REFUND_CHARGE
					# if you cannot refund it, that means the origonal charge
					# hasn't been settled yet, so you...

					if transaction.amount == charge_transaction.amount
						# have to void (but only if the refund is for the total amount)
						transaction.transaction_type = 'void'
						anet_transaction = AuthorizeNet::CIM::Transaction.new(@api_login, @api_key, :gateway => @gateway )
						response = anet_transaction.create_transaction_void(anet_transaction_id)

						puts response.xml if @enable_debug
					else
						# OR create a refund that is unlinked to the transaction
						anet_transaction = AuthorizeNet::CIM::Transaction.new(@api_login, @api_key, :gateway => @gateway )
						# anet_transaction.set_fields(:trans_id => nil)
						anet_transaction.create_transaction(
							:refund,
							refund_dollar_amount,
							transaction.customer_profile_reference,
							transaction.customer_payment_profile_reference,
							nil, #order
							{}, #options
						)

						# response = anet_transaction.create_transaction_refund(
						# 	nil,
						# 	refund_dollar_amount,
						# 	transaction.customer_profile_reference,
						# 	transaction.customer_payment_profile_reference
						# )

					end
				end

				direct_response = response.direct_response

				# process response
				if response.success? && direct_response.success?

					transaction.status = 'approved'
					transaction.reference_code = direct_response.transaction_id

					# if capture is successful, create transaction.
					transaction.save

					# sanity check
					# raise Exception.new( "SwellEcom::Transaction create errors #{transaction.errors.full_messages}" ) if transaction.errors.present?
				else
					puts response.xml if @enable_debug

					transaction.status = 'declined'
					transaction.message = response.message_text
					transaction.save

					# sanity check
					# raise Exception.new( "SwellEcom::Transaction create errors #{transaction.errors.full_messages}" ) if transaction.errors.present?

				end

				transaction
			end

			def update_subscription_payment_profile( subscription, args = {} )
				payment_profile = request_payment_profile( subscription.user, subscription.billing_address, args[:credit_card], errors: subscription.errors )

				return false unless payment_profile

				credit_card_dector = CreditCardValidations::Detector.new( args[:credit_card][:card_number] )

				new_properties = {
					'credit_card_ending_in' => credit_card_dector.number[-4,4],
					'credit_card_brand' => credit_card_dector.brand,
				}

				subscription.provider = PROVIDER_NAME
				subscription.provider_customer_profile_reference = payment_profile[:customer_profile_reference]
				subscription.provider_customer_payment_profile_reference = payment_profile[:customer_payment_profile_reference]
				subscription.properties = subscription.properties.merge( new_properties )
				subscription.payment_profile_expires_at	= SwellEcom::TransactionService.parse_credit_card_expiry( args[:credit_card][:expiration] ) if subscription.respond_to?(:payment_profile_expires_at)

				subscription.save

			end

			protected

			def get_order_customer_profile( order, args = {} )
				# find an existing customer profile
				subscriptions = order.order_items.select{ |order_item| order_item.item.is_a?( SwellEcom::Subscription ) && order_item.item.provider == PROVIDER_NAME }.collect(&:item)
				return { customer_profile_reference: subscriptions.first.provider_customer_profile_reference, customer_payment_profile_reference: subscriptions.first.provider_customer_payment_profile_reference } if subscriptions.present?

				raise Exception.new( 'cannot create payment profile without credit card info' ) unless args[:credit_card].present?

				payment_profile = request_payment_profile( order.user, order.billing_address, args[:credit_card], email: order.email, errors: order.errors )

				return payment_profile if payment_profile && order.errors.blank?

				return false
			end


			def request_payment_profile( user, billing_address, credit_card, args={} )
				anet_transaction = AuthorizeNet::CIM::Transaction.new(@api_login, @api_key, :gateway => @gateway )
				errors = args[:errors]

				billing_address_state = billing_address.state
				billing_address_state = billing_address.geo_state.try(:name) if billing_address_state.blank?
				billing_address_state = billing_address.geo_state.try(:abbrev) if billing_address_state.blank?

				anet_billing_address = AuthorizeNet::Address.new(
					:first_name		=> billing_address.first_name,
					:last_name		=> billing_address.last_name,
					# :company		=> nil,
					:street_address	=> "#{billing_address.street}\n#{billing_address.street2}".strip,
					:city			=> billing_address.city,
					:state			=> billing_address_state,
					:zip			=> billing_address.zip,
					:country		=> billing_address.geo_country.name,
					:phone			=> billing_address.phone,
				)

				# VALIDATE Credit card number
				credit_card_dector = CreditCardValidations::Detector.new(credit_card[:card_number])
				unless credit_card_dector.valid?
					errors.add( :base, 'Invalid Credit Card Number' ) if errors
					return false
				end

				# VALIDATE Credit card expirey
				expiration_time = SwellEcom::TransactionService.parse_credit_card_expiry( credit_card[:expiration] )
				if expiration_time.nil?
					errors.add( :base, 'Credit Card Expired is required') if errors
					return false
				elsif expiration_time.end_of_month < Time.now.end_of_month
					errors.add( :base, 'Credit Card has Expired') if errors
					return false
				end

				anet_credit_card = AuthorizeNet::CreditCard.new(
					credit_card[:card_number].gsub(/\s/,''),
					credit_card[:expiration],
					card_code: credit_card[:card_code],
				)

				anet_payment_profile = AuthorizeNet::CIM::PaymentProfile.new(
					:payment_method		=> anet_credit_card,
					:billing_address	=> anet_billing_address,
				)

				anet_customer_profile = AuthorizeNet::CIM::CustomerProfile.new(
					:email			=> args[:email] || user.try(:email),
					:id				=> user.try(:id),
					:phone			=> billing_address.phone,
					:address		=> anet_billing_address,
					:description	=> "#{anet_billing_address.first_name} #{anet_billing_address.last_name}"
				)
				anet_customer_profile.payment_profiles = anet_payment_profile


				# create a new customer profile
				response = anet_transaction.create_profile( anet_customer_profile )

				# recover a customer profile if it already exists.
				if response.message_code == ERROR_DUPLICATE_CUSTOMER_PROFILE
					puts response.xml if @enable_debug

					anet_transaction = AuthorizeNet::CIM::Transaction.new(@api_login, @api_key, :gateway => @gateway )


					profile_id = response.message_text.match( /(\d{4,})/)[1]

					response = anet_transaction.get_profile( profile_id.to_s )

					profile = response.profile
					customer_profile_id = response.profile_id

					customer_payment_profile = profile.payment_profiles.find do |payment_profile|
						payment_profile.payment_method.card_number.end_with?( anet_credit_card.card_number[-4,4] )
					end

					if customer_payment_profile.present?

						customer_payment_profile_id = customer_payment_profile.try(:customer_payment_profile_id)

					else

						# create a new payment profile for existing customer
						anet_transaction = AuthorizeNet::CIM::Transaction.new(@api_login, @api_key, :gateway => @gateway )
						response = anet_transaction.create_payment_profile( anet_payment_profile, profile )
						puts response.xml if @enable_debug
						customer_payment_profile_id = response.payment_profile_id

					end


					return { customer_profile_reference: customer_profile_id, customer_payment_profile_reference: customer_payment_profile_id }

				elsif response.success?

					customer_payment_profile_id = response.payment_profile_ids.last

					return { customer_profile_reference: response.profile_id, customer_payment_profile_reference: customer_payment_profile_id }

				else

					puts response.xml if @enable_debug

					if response.message_code == ERROR_INVALID_PAYMENT_PROFILE
						errors.add( :base, 'Invalid Payment Information') if errors
					else
						errors.add( :base, 'Unable to create customer profile') if errors
					end

				end

				return false

			end


		end

	end

end
