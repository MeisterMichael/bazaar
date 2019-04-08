module Bazaar

	class SubscriptionService < ::ApplicationService

		def initialize( args = {} )

			@order_class			= args[:order_class] || Bazaar.checkout_order_class_name

			@order_service			= args[:order_service]
			@order_service			||= Bazaar::OrderService.new( subscription_service: self )

		end

		def subscribe_ordered_plans( order, args = {} )
			# will only create plans for active orders
			raise Exception.new('Can only create subscriptions for active orders') unless order.active?

			order.order_offers.each do |order_offer|
				if order_offer.offer.recurring?
					order_offer.subscription = self.subscribe( order.user, order_offer.offer, args.merge( quantity: order_offer.quantity, order: order, subscription: order_offer.subscription ) )
					order_offer.save
				end
			end

		end

		def subscribe( user, offer, args = {} )
			start_at = args[:start_at] || Time.now
			quantity = args[:quantity] || 1

			plan = offer.subscription_plan

			if (order = args[:order]).present?

				args[:billing_address]	||= order.billing_address
				args[:shipping_address]	||= order.shipping_address
				args[:currency]			||= order.currency
				args[:provider]			||= order.provider
				args[:provider_customer_profile_reference] ||= order.provider_customer_profile_reference
				args[:provider_customer_payment_profile_reference] ||= order.provider_customer_payment_profile_reference
				args[:shipping_carrier_service_id] = order.order_items.shipping.first.item_id

				args[:discount] = order.order_items.discount.first.try(:item)

				if ( charge_transaction = order.transactions.charge.approved.first ).present? && charge_transaction.respond_to?( :properties )

					args[:credit_card_ending_in]	||= charge_transaction.credit_card_ending_in
					args[:credit_card_brand]		||= charge_transaction.credit_card_brand

				end

			end

			discount = Bazaar::Discount.find_by( args.delete(:discount_id) ) if args[:discount_id]
			discount ||= args[:discount]
			discount = nil unless discount.try(:for_subscriptions?)

			args[:trial_price]	||= args[:trial_amount] / quantity if args[:trial_amount]
			args[:price]		||= args[:amount] / quantity if args[:amount]
			args[:trial_price]	||= plan.trial_price
			args[:price]		||= plan.price

			args[:trial_amount]	||= args[:trial_price] * quantity
			args[:amount]		||= args[:price] * quantity

			args[:currency]		||= 'USD'

			trial_interval = plan.trial_interval_value.try( plan.trial_interval_unit )
			billing_interval = plan.billing_interval_value.try( plan.billing_interval_unit )

			current_period_end_at = start_at + billing_interval

			if plan.trial?
				trial_start_at = start_at
				trial_end_at = trial_start_at + trial_interval * plan.trial_max_intervals
				current_period_end_at = start_at + trial_interval
			end

			subscription = args[:subscription] || Subscription.new()
			subscription.attributes = {
				user: user,
				subscription_plan: plan,
				offer: offer,
				billing_address: args[:billing_address],
				shipping_address: args[:shipping_address],
				quantity: quantity,
				status: 'active',
				start_at: start_at,
				trial_start_at: trial_start_at,
				trial_end_at: trial_end_at,
				current_period_start_at: start_at,
				current_period_end_at: current_period_end_at,
				next_charged_at: current_period_end_at,
				billing_interval_value: plan.billing_interval_value,
				billing_interval_unit: plan.billing_interval_unit,
				currency: args[:currency],
				discount: discount,
				provider: args[:provider],
				provider_customer_profile_reference: args[:provider_customer_profile_reference],
				provider_customer_payment_profile_reference: args[:provider_customer_payment_profile_reference],
				payment_profile_expires_at: args[:payment_profile_expires_at],
				trial_amount: args[:trial_amount],
				amount: args[:amount],
				trial_price: args[:trial_price],
				price: args[:price],
				shipping_carrier_service_id: args[:shipping_carrier_service_id],
				shipping: args[:shipping],
				tax: args[:tax],
			}

			if subscription.respond_to? :properties
				subscription.properties = {
					'credit_card_ending_in'	=> args[:credit_card_ending_in],
					'credit_card_brand'		=> args[:credit_card_brand],
				}
			end

			subscription.save!

			log_event( user: user, name: 'subscribed', category: 'ecom', on: subscription, content: "started a subscription #{subscription.code} to #{plan.title}" )

			subscription
		end

		def generate_subscription_order( subscription, args = {} )
			time_now = args[:now] || Time.now

			# create order
			plan = subscription.subscription_plan
			offer = subscription.offer

			order = @order_class.constantize.new(
				billing_address: subscription.billing_address,
				shipping_address: subscription.shipping_address,
				user: subscription.user,
				generated_by: 'system_generaged',
				parent: subscription,
				email: subscription.user.email,
				currency: subscription.currency,
				provider: subscription.provider,
				provider_customer_profile_reference: subscription.provider_customer_profile_reference,
				provider_customer_payment_profile_reference: subscription.provider_customer_payment_profile_reference,
			)


			subscription_interval = Bazaar::OrderOffer.where( subscription: subscription ).joins(:order).merge(Bazaar::Order.positive_status).maximum(:subscription_interval) + 1

			order_offer = order.order_offers.new(
				offer: subscription.offer,
				subscription: subscription,
				tax_code: plan.tax_code,
				quantity: subscription.quantity,
				title: plan.title,
				subscription_interval: subscription_interval,
			)
			order_offer.price			= order_offer.offer.offer_prices.active.for_interval( subscription_interval ).first.price
			order_offer.subtotal	= order_offer.price * order_offer.quantity

			# apply the subscription discount to new orders
			discount = subscription.discount
			order.order_items.new( item: discount, order_item_type: 'discount', title: discount.title ) if discount.present? && discount.active? && discount.in_progress?( now: time_now ) && @order_service.discount_service.get_order_discount_errors( order, discount ).blank?

			order
		end

		def calculate_subscription_order( subscription, args = {} )
			order = generate_subscription_order( subscription, args = {} )
			order.status = 'draft'

			@order_service.calculate( order, shipping: { shipping_carrier_service_id: subscription.shipping_carrier_service_id, fixed_price: subscription.shipping } )

			order
		end

		def charge_subscription( subscription, args = {} )
			time_now = args[:now] || Time.now

			raise Exception.new("Subscription #{subscription.id } isn't ready to renew yet.  Currently it's #{time_now}, but subscription doesn't renew until #{subscription.next_charged_at}") unless subscription.next_charged_at < time_now
			raise Exception.new("Subscription #{subscription.id } isn't active, so can't be charged.") unless subscription.active?

			order = generate_subscription_order( subscription, args.merge( now: time_now ) )


			# process order
			begin

				transaction = @order_service.process( order, shipping: { shipping_carrier_service_id: subscription.shipping_carrier_service_id, fixed_price: subscription.shipping } )

			rescue Exception => e

				subscription.failed_attempts = subscription.failed_attempts + 1 if subscription.respond_to? :failed_attempts
				subscription.failed_message = "Exception: #{e.message}" if subscription.respond_to? :failed_message
				subscription.failed_at = Time.now if subscription.respond_to? :failed_at

				# mark subscription as failed if the transaction failed
				subscription.status = 'failed'

				subscription.save

				log_event( name: 'subscription_failed', category: 'ecom', on: subscription, content: "subscription #{subscription.code} failed to renew due to: #{subscription.failed_message}" )

				raise e

			end

			# Transaction fails if transaction is false or not approved.
			transaction_failed = !transaction || not( transaction.approved? )

			# Processing fails if
			# * the order has errors
			# * the order was not paid AND the transactions failed (free orders will not return a transaction)
			processing_failed = order.nested_errors.present?
			processing_failed = true if not( order.paid? ) && transaction_failed

			if processing_failed

				if transaction.present? && transaction.persisted?

					transaction.parent_obj = subscription
					transaction.save

				else

					# if no transaction was created, create one to log the error
					transaction = Bazaar::Transaction.create(
						message: order.nested_errors.join(' * '),
						parent_obj: subscription,
						status: 'declined',
						transaction_type: 'charge',
						amount: order.total,
						currency: order.currency,
					)

				end

				# annotate how, how often, and when the subscription failed
				subscription.failed_attempts = subscription.failed_attempts + 1 if subscription.respond_to? :failed_attempts
				subscription.failed_message = transaction.message if subscription.respond_to? :failed_message
				subscription.failed_at = transaction.created_at if subscription.respond_to? :failed_at

				# mark subscription as failed if the transaction failed
				subscription.status = 'failed'

				subscription.save

				order.errors.add(:base, :processing_error, message: 'Transaction failed') if !transaction || not( transaction.approved? )

			else
				order.save

				log_event( user: subscription.user, name: 'renewal', on: subscription, content: "auto renewed a subscription #{subscription.code}" )

				# remove discount after use, if it is not for more than one order
				subscription.discount = nil unless subscription.discount.try(:for_subscriptions?)

				subscription.failed_attempts = 0 if subscription.respond_to? :failed_attempts

				# update the subscriptions next date
				update_next_charged_at( subscription )

				subscription.save

			end

			order

		end

		def update_next_charged_at( subscription )
			interval = nil
			if subscription.is_next_interval_a_trial?
				interval = plan.trial_interval_value.try(plan.trial_interval_unit)
			else
				interval = subscription.billing_interval_value.try(subscription.billing_interval_unit)
			end

			subscription.current_period_start_at = Time.now
			subscription.current_period_end_at = subscription.current_period_start_at + interval
			subscription.next_charged_at = subscription.current_period_end_at
		end

		def update_payment_profile( subscription, args = {} )
			@order_service.transaction_service.update_subscription_payment_profile( subscription, args )
		end

	end


end
