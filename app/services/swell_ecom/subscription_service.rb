module SwellEcom

	class SubscriptionService

		def charge_subscriptions( args = {} )

			now = args[:now] || Time.now

			SwellEcom::Subscription.active.where( 'next_charged_at < :now', now: now ).find_each do |subscription|

				charge_subscription( subscription )

			end

		end

		def charge_subscription( subscription )

			@shipping_service 		||= SwellEcom.shipping_service_class.constantize.new( SwellEcom.shipping_service_config )
			@tax_service			||= SwellEcom.tax_service_class.constantize.new( SwellEcom.tax_service_config )
			@transaction_service	||= SwellEcom.transaction_service_class.constantize.new( SwellEcom.transaction_service_config )

			# create order, process transaction

			plan = subscription.subscription_plan

			order = Order.new(
				billing_address: subscription.billing_address,
				shipping_address: subscription.shipping_address,
				status: 'placed',
				user: subscription.user,
				generated_by: 'system_generaged',
				parent: subscription,
				email: subscription.user.email,
				currency: subscription.currency,
			)

			interval = nil

			if subscription.is_next_interval_a_trial?
				interval = plan.trial_interval_value.try(plan.trial_interval_unit)

				order.order_items.new item: subscription, price: plan.trial_price, subtotal: plan.trial_price * subscription.quantity, order_item_type: 'prod', quantity: subscription.quantity, title: plan.title, tax_code: plan.tax_code
			else
				interval = plan.billing_interval_value.try(plan.billing_interval_unit)

				order.order_items.new item: subscription, price: plan.price, subtotal: plan.price * subscription.quantity, order_item_type: 'prod', quantity: subscription.quantity, title: plan.title, tax_code: plan.tax_code
			end

			@shipping_service.calculate( order )
			@tax_service.calculate( order )
			@transaction_service.process( order )

			if order.errors.present?

				# mark subscription as failed if the transaction failed
				subscription.failed!

			else
				order.save

				subscription.current_period_start_at = subscription.current_period_start_at + interval
				subscription.current_period_end_at = subscription.current_period_end_at + interval
				subscription.next_charged_at = subscription.next_charged_at + interval
				subscription.save

				OrderMailer.receipt( order ).deliver_now

			end

			subscription

		end

	end


end
