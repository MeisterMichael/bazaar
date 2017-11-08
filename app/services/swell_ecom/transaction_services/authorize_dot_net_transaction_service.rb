require 'authorizenet'

module SwellEcom

	module TransactionServices

		class AuthorizeDotNetTransactionService < SwellEcom::TransactionService

			def initialize( args = {} )
				@api_login	= args[:API_LOGIN_ID] || ENV['AUTHORIZE_DOT_NET_API_LOGIN_ID']
				@api_key	= args[:TRANSACTION_API_KEY] || ENV['AUTHORIZE_DOT_NET_TRANSACTION_API_KEY']
				@gateway	= ( args[:API_LOGIN_ID] || ENV['AUTHORIZE_DOT_NET_GATEWAY'] || :sandbox ).to_sym
			end

			def cancel_subscription( subscription )
				# @todo
			end

			def process( order, args = {} )
				self.calculate( order )
				return false if order.errors.present?

				one_time_order_items	= order.order_items.select{ |order_items| order_items.item.is_a? Product }
				plan_order_items		= order.order_items.select{ |order_items| order_items.item.is_a? SubscriptionPlan }

				plan_order_items.each do |order_item|
					subscription	= order_item.subscription
					plan			= order_item.item

					same_trial_and_billing_interval = plan.billing_interval_unit == plan.trial_interval_unit && plan.billing_interval_value == plan.trial_interval_value

					# if NO trial, or trial is on the same cadence as the rest of
					# the subscription, then process a single subscription.
					if same_trial_and_billing_interval || plan.trial_max_intervals == 0

						# offset by one interval, because initial is transacted
						# now, as part of this order
						interval_duration = plan.billing_interval_value.try( plan.billing_interval_unit )
						start_date = subscription.start_at + interval_duration

						process_subscription(
							order, subscription,
							:amount			=> subscription.amount,
							:trial_amount	=> subscription.trial_amount,
							:schedule => {
								:length				=> plan.billing_interval_value,
								:unit				=> plan.billing_interval_unit,
								:start_date			=> start_date,
								:total_occurrences	=> nil,
								:trial_occurrences	=> plan.trial_max_intervals,
							},
							:credit_card => args[:credit_card]
						)

					# if HAS a trial, which is ONE interval, and is NOT the same
					# candence as the rest of the subscription, then delay the
					# subscription by the length of the trial, and pay the trial
					# upfront.
					else


						if plan.trial_max_intervals > 1

							raise Exception.new('Unsupported Trail Subscription')

							# offset by one interval, because initial is transacted
							# now, as part of this order
							# total_occurrences	= plan.trial_max_intervals - 1
							# trial_duration		= plan.trial_interval_value.try( plan.trial_interval_unit )
							# start_date = subscription.start_at + interval_duration

							# process_subscription(
							# 	order, subscription,
							# 	:amount => subscription.trial_amount,
							# 	:schedule => {
							# 		:length				=> subscription.trial_interval_value,
							# 		:unit				=> subscription.trial_interval_unit,
							# 		:start_date			=> start_date,
							# 		:total_occurrences	=> total_occurrences,
							# 	}
							# 	:credit_card => args[:credit_card]
							# )
						end

						# offset by trial duration, as the trial has it's own sub
						trial_duration	= plan.trial_interval_value.try( plan.trial_interval_unit ) * plan.trial_max_intervals
						start_date		= subscription.start_at + trial_duration

						process_subscription(
							order, subscription,
							:amount 		=> subscription.amount,
							:trial_amount 	=> subscription.trial_amount,
							:schedule => {
								:length				=> plan.billing_interval_value,
								:unit				=> plan.billing_interval_unit,
								:start_date			=> start_date,
								:total_occurrences	=> nil,
							},
							:credit_card => args[:credit_card]
						)

					end

				end


				process_order( order, :credit_card => args[:credit_card] )

				return false

			end

			def refund( args = {} )
				# @todo
				throw Exception.new('@todo AuthorizeDotNetTransactionService#refund')

				begin

					transaction = Transcation.new( args )
					transaction.transaction_type	= 'refund'
					transaction.provider			= 'Authorize.net'
					transaction.currency			||= transaction.parent.try(:currency)


					# @todo process


					transaction.reference_code		= nil
					transaction.status				= 'approved'

					return transaction

				rescue Exception => e

				end

				return false

			end

			def update_subscription( subscription )
				# @todo
			end

			# protected

			def process_order( order, args = {} )
				# @todo process order
				throw Exception.new('@todo AuthorizeDotNetTransactionService#process_order')
			end

			def process_subscription( order, subscription, args = {} )
				schedule	= args[:schedule]
				credit_card	= args[:credit_card]
				plan		= subscription.subscription_plan

				total_occurrences	= :unlimited
				total_occurrences	= schedule[:total_occurrences] if schedule[:total_occurrences].present? && schedule[:total_occurrences] > 0
				trial_occurrences	= schedule[:trial_occurrences]
				amount				= schedule[:amount]
				trial_amount		= schedule[:trial_amount]

				unit_multiplier = 1
				unit = AuthorizeNet::ARB::Subscription::IntervalUnits::MONTH
				unit = AuthorizeNet::ARB::Subscription::IntervalUnits::DAY if schedule[:unit] == 'day' || schedule[:unit] == 'week'
				unit_multiplier = 7 if schedule[:unit] == 'week'
				length = schedule[:length] * unit_multiplier

				start_date = schedule[:start_at]

				anet_credit_card = AuthorizeNet::CreditCard.new(
					credit_card[:card_number],
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


				anet_subscription = AuthorizeNet::ARB::Subscription.new(
					:name => plan.title,
					:invoice_number => order.code,
					:description => plan.recurring_statement_descriptor,
					:subscription_id => nil,
					:customer => anet_customer,
					:credit_card => anet_credit_card,
					:billing_address => anet_billing_address,
					:shipping_address => anet_shipping_address,

					:unit => unit,
					:length => length,
					:start_date => start_date,
					:total_occurrences => total_occurrences,
					:trial_occurrences => trial_occurrences,
					:amount => amount,
					:trial_amount => trial_amount,
				)

				anet_transaction = AuthorizeNet::ARB::Transaction.new(@api_login, @api_key, :gateway => @gateway )

				response = anet_transaction.create( anet_subscription )

				if response.success?
					# @todo validate success
					puts "subscription success #{response.subscription_id}"
					return true
				else
					# @todo handle errors
					puts "subscription error"
					raise Exception.new('subscription error')
					return false
				end
			end

		end

	end

end
