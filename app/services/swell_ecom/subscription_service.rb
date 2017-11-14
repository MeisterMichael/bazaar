class SubscriptionService

	def charge_subscriptions( args = {} )

		now = args[:now] || Time.now

		SwellEcom::Subscription.active.where( 'next_charged_at < :now', now: now ).find_each do |subscription|

			renew_subscription( subscription )

		end

	end

	def renew_subscription( subscription )

		@shipping_service 		||= SwellEcom.shipping_service_class.constantize.new( SwellEcom.shipping_service_config )
		@tax_service			||= SwellEcom.tax_service_class.constantize.new( SwellEcom.tax_service_config )
		@transaction_service	||= SwellEcom.transaction_service_class.constantize.new( SwellEcom.transaction_service_config )

		# create order, process transaction

		plan = subscription.subscription_plan

		order = Order.new(
			billing_address: subscription.billing_address,
			shipping_address: subscription.shipping_address,
		)

		if subscription.trial?
			order.order_items.new item: subscription, price: plan.trial_price, subtotal: plan.trial_price * order_item.quantity, order_item_type: 'prod', quantity: subscription.quantity, title: plan.title, tax_code: plan.tax_code
		else
			order.order_items.new item: subscription, price: plan.price, subtotal: plan.price * order_item.quantity, order_item_type: 'prod', quantity: subscription.quantity, title: plan.title, tax_code: plan.tax_code
		end

		@shipping_service.calculate( order )
		@tax_service.calculate( order )
		@transaction_service.process( order )

		if order.errors.present?

			# mark subscription as failed if the transaction failed
			subscription.failed!

		else

			OrderMailer.receipt( @order ).deliver_now

		end

		subscription

	end

end
