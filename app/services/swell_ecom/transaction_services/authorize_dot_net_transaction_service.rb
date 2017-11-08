require 'authorizenet'

module SwellEcom

	module TransactionServices

		class AuthorizeDotNetTransactionService < SwellEcom::TransactionService

			PROVIDER_NAME = 'Authorize.net'
			ERROR_DUPLICATE_CUSTOMER_PROFILE = 'E00039'

			def initialize( args = {} )
				@api_login	= args[:API_LOGIN_ID] || ENV['AUTHORIZE_DOT_NET_API_LOGIN_ID']
				@api_key	= args[:TRANSACTION_API_KEY] || ENV['AUTHORIZE_DOT_NET_TRANSACTION_API_KEY']
				@gateway	= ( args[:API_LOGIN_ID] || ENV['AUTHORIZE_DOT_NET_GATEWAY'] || :sandbox ).to_sym
			end

			def process( order, args = {} )
				self.calculate( order )
				return false if order.errors.present?

				profiles = get_customer_profile( order, credit_card: args[:credit_card] )
				return false if profiles == false

				anet_order = nil
				# anet_order = AuthorizeNet::Order.new()
		        # anet_order.invoice_num = order.code
		        # anet_order.description =  'This order includes invoice num'
		        # anet_order.po_num = 'PO_12345'
				# order.order_items.select(&:prod?).each do |order_item|
				# 	anet_order.add_line_item(
				# 		order_item.item.code, 		#id
				# 		order_item.title,			#name
				# 		nil,						#description
				# 		order_item.quantity,		#quantity
				# 		order_item.price / 100.0,	# price
				# 		1							# taxable
				# 	)
				# end

				# create capture
				anet_transaction = AuthorizeNet::CIM::Transaction.new(@api_login, @api_key, :gateway => @gateway )
				amount = order.total / 100.0 # convert cents to dollars
		        response = anet_transaction.create_transaction_auth_capture( amount, profiles[:customer_profile_id], profiles[:payment_profile_id], anet_order )
				direct_response = response.direct_response

				puts response.xml

				raise Exception.new("create auth capture error: #{response.message_text}") unless response.success?


				# process response
				if response.success? && direct_response.success?

					# if capture is successful, save order, and create transaction.
					if order.save

						# update any subscriptions with profile ids
						order.order_items.each do |order_item|
							if order_item.subscription.present?
								order_item.subscription.provider = PROVIDER_NAME
								order_item.subscription.provider_customer_profile_reference = profiles[:customer_profile_id]
								order_item.subscription.provider_customer_payment_profile_reference = profiles[:payment_profile_id]
								order_item.subscription.save
							end
						end

						transaction = SwellEcom::Transaction.create( parent_obj: order, transaction_type: 'charge', reference_code: direct_response.transaction_id, provider: PROVIDER_NAME, amount: order.total, currency: order.currency, status: 'approved' )

						raise Exception.new( "SwellEcom::Transaction create errors #{transaction.errors.full_messages}" ) if transaction.errors.present?

						return true

					end

				else

					orders.status = 'declined'

					if orders.save
						Transaction.create( transaction_type: 'charge', reference_code: direct_response.try(:transaction_id), provider: PROVIDER_NAME, amount: order.total, currency: order.currency, status: 'declined', message: response.message_text )
					end

					order.errors.add(:base, :processing_error, message: "Transaction declined.")

				end


				return false
			end

			def refund( args = {} )
				# @todo
				throw Exception.new('@todo AuthorizeDotNetTransactionService#refund')

				begin

					transaction = Transcation.new( args )
					transaction.transaction_type	= 'refund'
					transaction.provider			= PROVIDER_NAME
					transaction.currency			||= transaction.parent.try(:currency)


					# @todo process


					transaction.reference_code		= nil
					transaction.status				= 'approved'

					return transaction

				rescue Exception => e

				end

				return false

			end

			protected

			def get_customer_profile( order, args = {} )
				anet_transaction = AuthorizeNet::CIM::Transaction.new(@api_login, @api_key, :gateway => @gateway )

				# find an existing customer profile
				subscriptions = order.order_items.select{ |order_item| order_item.item.is_a?( SwellEcom::Subscription ) && order_item.item == PROVIDER_NAME }.collect(&:item)
				return { customer_profile_id: subscriptions.first.provider_customer_profile_reference, payment_profile_id: subscriptions.first.provider_customer_payment_profile_reference } if subscriptions.present?

				raise Exception.new( 'cannot create payment profile without credit card info' ) unless args[:credit_card].present?

				billing_address_state = order.billing_address.state
				billing_address_state = order.billing_address.geo_state.try(:name) if billing_address_state.blank?
				billing_address_state = order.billing_address.geo_state.try(:abbrev) if billing_address_state.blank?

				anet_billing_address = AuthorizeNet::Address.new(
					:first_name		=> order.billing_address.first_name,
					:last_name		=> order.billing_address.last_name,
					# :company		=> nil,
					:street_address	=> "#{order.billing_address.street}\n#{order.billing_address.street2}".strip,
					:city			=> order.billing_address.city,
					:state			=> billing_address_state,
					:zip			=> order.billing_address.zip,
					:country		=> order.billing_address.geo_country.name,
					:phone			=> order.billing_address.phone,
				)

				credit_card = args[:credit_card]
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
					:email			=> order.user.email,
					:id				=> order.user.id,
					:phone			=> order.billing_address.phone,
					:address		=> anet_billing_address,
					:description	=> "#{anet_billing_address.first_name} #{anet_billing_address.last_name}"
				)
				anet_customer_profile.payment_profiles = anet_payment_profile


				# create a new customer profile
				response = anet_transaction.create_profile( anet_customer_profile )
				puts response.success?
				puts response.profile_id
				puts response.payment_profile_ids
				puts response.xml

				# recover a customer profile if it already exists.
				if response.message_code == ERROR_DUPLICATE_CUSTOMER_PROFILE
					anet_transaction = AuthorizeNet::CIM::Transaction.new(@api_login, @api_key, :gateway => @gateway )

					profile_id = response.message_text.match( /(\d{4,})/)[1]

					response = anet_transaction.get_profile( profile_id.to_s )
					customer_profile_id = response.profile_id
					customer_payment_profile_id = response.profile.payment_profiles.first.try(:customer_payment_profile_id)

					return { customer_profile_id: customer_profile_id, payment_profile_id: customer_payment_profile_id }

				elsif not( response.success? )
					raise Exception.new("create profile error #{response.message_text}")
				end

				if response.success?

					puts response.profile_id
					puts response.payment_profile_id

					return { customer_profile_id: response.profile_id, payment_profile_id: response.payment_profile_id }
				else
					order.errors.add(:base, :processing_error, message: 'Unable to create customer profile')

					return false
				end

			end

			def process_order( order, args = {} )
				# @todo process order
				raise Exception.new('@todo AuthorizeDotNetTransactionService#process_order')
			end

			def process_subscription( order, subscription, args = {} )
				schedule	= args[:schedule]
				credit_card	= args[:credit_card]
				plan		= subscription.subscription_plan

				total_occurrences	= :unlimited
				total_occurrences	= schedule[:total_occurrences] if schedule[:total_occurrences].present? && schedule[:total_occurrences] > 0
				trial_occurrences	= schedule[:trial_occurrences]

				amount				= (args[:amount] / 100.0)

				trial_amount		= 0.0
				trial_amount		= (args[:trial_amount] / 100.0) if args[:trial_amount].present?

				unit_multiplier = 1
				unit = AuthorizeNet::ARB::Subscription::IntervalUnits::MONTH
				unit = AuthorizeNet::ARB::Subscription::IntervalUnits::DAY if schedule[:unit] == 'day' || schedule[:unit] == 'week'
				unit_multiplier = 7 if schedule[:unit] == 'week'
				length = schedule[:length] * unit_multiplier

				start_date = schedule[:start_date]

				puts "JSON.pretty_generate schedule"
				puts JSON.pretty_generate schedule

				anet_credit_card = AuthorizeNet::CreditCard.new(
					credit_card[:card_number].gsub(/\s/,''),
					credit_card[:expiration],
					card_code: credit_card[:card_code],
				)

				customer_id = order.user.try(:id).to_s if order.user.present?
				anet_customer = AuthorizeNet::Customer.new(
					:email			=> order.user.try(:email),
					:id				=> customer_id,
					:phone_number	=> order.billing_address.phone,
				)

				anet_billing_address = AuthorizeNet::Address.new(
					:first_name		=> order.billing_address.first_name,
					:last_name		=> order.billing_address.last_name,
					# :company		=> nil,
					:address		=> "#{order.billing_address.street}\n#{order.billing_address.street2}".strip,
					:city			=> order.billing_address.city,
					:state			=> order.billing_address.state || order.billing_address.geo_state.try(:name),
					:zip			=> order.billing_address.zip,
					:country		=> order.billing_address.geo_country.name,
					:phone_number	=> order.billing_address.phone,
				)

				anet_shipping_address = AuthorizeNet::Address.new(
					:first_name		=> order.shipping_address.first_name,
					:last_name		=> order.shipping_address.last_name,
					# :company		=> nil,
					:address		=> "#{order.shipping_address.street}\n#{order.shipping_address.street2}".strip,
					:city			=> order.shipping_address.city,
					:state			=> order.shipping_address.state || order.shipping_address.geo_state.try(:name),
					:zip			=> order.shipping_address.zip,
					:country		=> order.shipping_address.geo_country.name,
				)


				anet_subscription_attributes = {

					:name => plan.title,
					:invoice_number => order.code,
					:description => plan.billing_statement_descriptor,
					:subscription_id => nil,
					:customer => anet_customer,
					:credit_card => anet_credit_card,
					:billing_address => anet_billing_address,
					:shipping_address => anet_shipping_address,

					:unit => unit,
					:length => length,
					:start_date => start_date,
					:total_occurrences => total_occurrences,
					:trial_occurrences => trial_occurrences || 0,
					:amount => amount,
					:trial_amount => trial_amount,
				}
				puts "anet_subscription_attributes #{JSON.pretty_generate anet_subscription_attributes}"
				anet_subscription = AuthorizeNet::ARB::Subscription.new( anet_subscription_attributes )

				anet_transaction = AuthorizeNet::ARB::Transaction.new(@api_login, @api_key, :gateway => @gateway )

				response = anet_transaction.create( anet_subscription )


				raise Exception.new("subscription error #{response.message_text}") unless response.success?

				return true
			end

		end

	end

end
