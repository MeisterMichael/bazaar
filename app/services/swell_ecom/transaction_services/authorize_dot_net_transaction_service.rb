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

				# @todo
				throw Exception.new('@todo AuthorizeDotNetTransactionService#process')
				# process subscription if order includes a plan

				anet_credit_card = AuthorizeNet::CreditCard.new(
					args[:credit_card][:card_number],
					args[:credit_card][:expiration],
					card_code: args[:credit_card][:card_code],
				)

				anet_customer = AuthorizeNet::Customer.new(
					:email			=> order.user.email,
					:id				=> order.user.id.to_s,
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


				one_time_order_items	= order.order_items.select{ |order_items| order_items.item.is_a? Product }
				plan_order_items		= order.order_items.select{ |order_items| order_items.item.is_a? Plan }

				plan_order_items.each do |order_item|
					plan			= order_item.item
					subscription	= order_item.subscription

					recurring_interval_unit_multiplier = 1
					recurring_interval_unit = AuthorizeNet::ARB::Subscription::IntervalUnits::MONTH
					recurring_interval_unit = AuthorizeNet::ARB::Subscription::IntervalUnits::DAY if subscription.recurring_interval == 'day' || subscription.recurring_interval == 'week'
					recurring_interval_unit_multiplier = 7 if subscription.recurring_interval == 'week'
					recurring_interval_value = plan.recurring_interval_value * recurring_interval_unit_multiplier

					trial_interval_unit_multiplier = 1
					trial_interval_unit = AuthorizeNet::ARB::Subscription::IntervalUnits::MONTH
					trial_interval_unit = AuthorizeNet::ARB::Subscription::IntervalUnits::DAY if subscription.trial_interval == 'day' || subscription.trial_interval == 'week'
					trial_interval_unit_multiplier = 7 if subscription.trial_interval == 'week'
					trial_interval_value = plan.trial_interval_value * trial_interval_unit_multiplier

					total_occurrences = :unlimited
					total_occurrences = plan.recurring_max_intervals + plan.trial_max_intervals if plan.recurring_max_intervals.present?

					# if NO trial, or trial is on the same cadence as the rest of
					# the subscription, then process a single subscription.
					if ( recurring_interval_value == trial_interval_value && plan.recurring_interval == plan.trial_interval ) || plan.trial_max_intervals == 0

						anet_subscription = AuthorizeNet::ARB::Subscription.new(
							:name => plan.name,
							:length => recurring_interval_value,
							:unit => recurring_interval_unit,
							:start_date => subscription.start_date,
							:total_occurrences => total_occurrences,
							:trial_occurrences => plan.trial_max_intervals,
							:amount => subscription.amount,
							:trial_amount => subscription.trial_amount,
							:invoice_number => order.code,
							:description => plan.recurring_statement_descriptor,
							:subscription_id => nil,
							:customer => anet_customer,
							:credit_card => anet_credit_card,
							:billing_address => anet_billing_address,
							:shipping_address => anet_shipping_address,
						)

						anet_transaction = AuthorizeNet::ARB::Transaction.new(@api_login, @api_key, :gateway => @gateway )
						response = anet_transaction.create( anet_subscription )

						if response.success?
							# @todo validate success
						else
							# @todo handle errors
						end

					# if HAS a trial, which is ONE interval, and is NOT the same
					# candence as the rest of the subscription, then delay the
					# subscription by the length of the trial, and pay the trial
					# upfront.
					else
						raise Exception.new('Unsupported Trail Subscription') unless plan.trial_max_intervals == 1


						# postpone the start of the subscription, by the length
						# of the trial.
						trial_duration = plan.trial_interval_value.try( plan.trial_recurring_interval ) * plan.trial_max_intervals
						recurring_start_date = subscription.start_date + trial_duration

						anet_subscription = AuthorizeNet::ARB::Subscription.new(
							:name => plan.name,
							:length => recurring_interval_value,
							:unit => recurring_interval_unit,
							:start_date => recurring_start_date,
							:total_occurrences => total_occurrences,
							:trial_occurrences => nil,
							:amount => subscription.amount,
							:trial_amount => nil,
							:invoice_number => order.code,
							:description => plan.recurring_statement_descriptor,
							:subscription_id => nil,
							:customer => anet_customer,
							:credit_card => anet_credit_card,
							:billing_address => anet_billing_address,
							:shipping_address => anet_shipping_address,
						)


						anet_transaction = AuthorizeNet::ARB::Transaction.new(@api_login, @api_key, :gateway => @gateway )
						response = anet_transaction.create( anet_subscription )

						if response.success?
							# @todo validate success
						else
							# @todo handle errors
						end

						if plan.trial_max_intervals > 1

							# @todo create a trial subscription.

						end

					end

				end


				# @todo process order
				order

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

		end

	end

end
