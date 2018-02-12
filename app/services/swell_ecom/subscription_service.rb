module SwellEcom

	class SubscriptionService

		def initialize( args = {} )

			@order_service			= args[:order_service]
			@order_service			||= SwellEcom::OrderService.new

			@transaction_service	= args[:transaction_service]
			@transaction_service	||= SwellEcom.transaction_service_class.constantize.new( SwellEcom.transaction_service_config )

		end

		def subscribe_ordered_plans( order, args = {} )
			# will only create plans for active orders
			raise Exception.new('Can only create subscriptions for active orders') unless order.active?

			order.order_items.each do |order_item|
				if order_item.item.is_a? SwellEcom::SubscriptionPlan

					order_item.subscription ||= self.subscribe( order.user, order_item.item, args.merge( quantity: order_item.quantity, order: order ) )
					order_item.save

				end
			end

		end

		def subscribe( user, plan, args = {} )
			start_at = args[:start_at] || Time.now
			quantity = args[:quantity] || 1

			if (order = args[:order]).present?

				args[:billing_address]	||= order.billing_address
				args[:shipping_address]	||= order.shipping_address
				args[:currency]			||= order.currency
				args[:provider]			||= order.provider
				args[:provider_customer_profile_reference] ||= order.provider_customer_profile_reference
				args[:provider_customer_payment_profile_reference] ||= order.provider_customer_payment_profile_reference

				args[:discount] = order.order_items.discount.first.try(:item)

			end

			args[:trial_amount]	||= plan.trial_price * quantity
			args[:amount]		||= plan.price * quantity

			trial_interval = plan.trial_interval_value.try( plan.trial_interval_unit )
			billing_interval = plan.billing_interval_value.try( plan.billing_interval_unit )

			current_period_end_at = start_at + billing_interval

			if plan.trial?
				trial_start_at = start_at
				trial_end_at = trial_start_at + trial_interval * plan.trial_max_intervals
				current_period_end_at = start_at + trial_interval
			end

			subscription = Subscription.create!(
				user: user,
				subscription_plan: plan,
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
				currency: args[:currency],
				discount: args[:discount],
				provider: args[:provider],
				provider_customer_profile_reference: args[:provider_customer_profile_reference],
				provider_customer_payment_profile_reference: args[:provider_customer_payment_profile_reference],
				payment_profile_expires_at: args[:payment_profile_expires_at],
				trial_amount: args[:trial_amount],
				amount: args[:amount],
			)

			subscription
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

				order.order_items.new item: subscription, subscription: subscription, price: plan.trial_price, sku: plan.trial_sku, subtotal: plan.trial_price * subscription.quantity, order_item_type: 'prod', quantity: subscription.quantity, title: plan.title, tax_code: plan.tax_code
			else
				interval = plan.billing_interval_value.try(plan.billing_interval_unit)

				order.order_items.new item: subscription, subscription: subscription, price: plan.price, sku: plan.product_sku, subtotal: plan.price * subscription.quantity, order_item_type: 'prod', quantity: subscription.quantity, title: plan.title, tax_code: plan.tax_code
			end

			# apply the subscription discount to new orders
			discount = subscription.discount
			order.order_items.new( item: discount, order_item_type: 'discount', title: discount.title ) if discount.present? && discount.active? && discount.in_progress?( now: time_now )

			# process order
			transaction = @order_service.process( order )

			# handle response
			if order.errors.present? || !transaction || not( transaction.approved? )

				# mark subscription as failed if the transaction failed
				subscription.failed!
				order.errors.add(:base, :processing_error, message: 'Transaction failed') if !transaction || not( transaction.approved? )

			else
				order.save

				# update the subscriptions next date
				subscription.current_period_start_at = subscription.current_period_start_at + interval
				subscription.current_period_end_at = subscription.current_period_end_at + interval
				subscription.next_charged_at = subscription.next_charged_at + interval
				subscription.save

			end

			order

		end

		def update_payment_profile( subscription, args = {} )
			@transaction_service.update_subscription_payment_profile( subscription, args )
		end

	end


end
