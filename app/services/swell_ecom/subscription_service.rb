module SwellEcom

	class SubscriptionService

		def initialize( args = {} )

			@shipping_service		= args[:shipping_service]
			@tax_service			= args[:tax_service]
			@transaction_service	= args[:transaction_service]

			@shipping_service 		||= SwellEcom.shipping_service_class.constantize.new( SwellEcom.shipping_service_config )
			@tax_service			||= SwellEcom.tax_service_class.constantize.new( SwellEcom.tax_service_config )
			@transaction_service	||= SwellEcom.transaction_service_class.constantize.new( SwellEcom.transaction_service_config )

		end

		def charge_subscription( subscription, args = {} )
			time_now = args[:now] || Time.now

			raise Exception.new("Subscription #{subscription.id } isn't ready to renew yet.  Currently it's #{time_now}, but subscription doesn't renew until #{subscription.next_charged_at}") unless subscription.next_charged_at < time_now
			raise Exception.new("Subscription #{subscription.id } isn't active, so can't be charged.") unless subscription.active?

			# create order
			plan = subscription.subscription_plan

			order = Order.new(
				billing_address: subscription.billing_address,
				shipping_address: subscription.shipping_address,
				user: subscription.user,
				generated_by: 'system_generaged',
				parent: subscription,
				email: subscription.user.email,
				currency: subscription.currency,
			)

			interval = nil

			if subscription.is_next_interval_a_trial?
				interval = plan.trial_interval_value.try(plan.trial_interval_unit)

				order.order_items.new item: subscription, price: plan.trial_price, sku: plan.trial_sku, subtotal: plan.trial_price * subscription.quantity, order_item_type: 'prod', quantity: subscription.quantity, title: plan.title, tax_code: plan.tax_code
			else
				interval = plan.billing_interval_value.try(plan.billing_interval_unit)

				order.order_items.new item: subscription, price: plan.price, sku: plan.product_sku, subtotal: plan.price * subscription.quantity, order_item_type: 'prod', quantity: subscription.quantity, title: plan.title, tax_code: plan.tax_code
			end

			# process order
			@shipping_service.calculate( order )
			@tax_service.calculate( order )
			transaction = @transaction_service.process( order )

			# handle response
			if order.errors.present? || !transaction || not( transaction.approved? )

				# mark subscription as failed if the transaction failed
				subscription.failed!
				order.errors.add(:base, :processing_error, message: 'Transaction failed') if !transaction || not( transaction.approved? )

			else
				order.save

				@tax_service.process( order ) if @tax_service.respond_to? :process

				# update the subscriptions next date
				subscription.current_period_start_at = subscription.current_period_start_at + interval
				subscription.current_period_end_at = subscription.current_period_end_at + interval
				subscription.next_charged_at = subscription.next_charged_at + interval
				subscription.save

			end

			order

		end

	end


end
