module Bazaar

	class SubscriptionService < ::ApplicationService

		def initialize( args = {} )

			@order_class			= args[:order_class] || Bazaar.checkout_order_class_name

			@order_service			= args[:order_service]
			@order_service			||= Bazaar.checkout_order_service_class.constantize.new( subscription_service: self )

		end

		def subscribe_ordered_plans( order, args = {} )
			# will only create subscriptions for active orders
			raise Exception.new('Can only create subscriptions for active orders') unless order.active? || order.review?

			order.order_offers.each do |order_offer|
				if order_offer.offer.recurring? && ( order_offer.subscription.nil? || order_offer.subscription.trash? )

					order_offer.subscription = self.subscribe( order.user, order_offer.offer, args.merge( quantity: order_offer.quantity, order: order, subscription: order_offer.subscription, interval: order_offer.subscription_interval ) )
					order_offer.save

				end
			end

		end

		def subscribe( user, offer, args = {} )
			start_at 					= args[:start_at] || Time.now
			quantity 					= args[:quantity] || 1
			interval 					= args[:interval] || 1
			next_subscription_interval	= args[:next_subscription_interval] || 1

			if (order = args[:order]).present?

				args[:billing_user_address]		||= order.billing_user_address
				args[:shipping_user_address]	||= order.shipping_user_address
				args[:billing_address]				||= order.billing_address
				args[:shipping_address]				||= order.shipping_address
				args[:currency]								||= order.currency
				args[:provider]								||= order.provider
				args[:transaction_provider]		||= order.transaction_provider
				args[:merchant_identification]||= order.merchant_identification
				args[:provider_customer_profile_reference] ||= order.provider_customer_profile_reference
				args[:provider_customer_payment_profile_reference] ||= order.provider_customer_payment_profile_reference
				args[:shipping_carrier_service_id] = order.order_items.shipping.first.try(:item_id)

				args[:discount] = order.order_items.discount.first.try(:item)

				if ( charge_transaction = order.transactions.charge.approved.first ).present? && charge_transaction.respond_to?( :properties )

					args[:credit_card_ending_in]	||= charge_transaction.credit_card_ending_in
					args[:credit_card_brand]		||= charge_transaction.credit_card_brand

				end

			end

			discount = Bazaar::Discount.find_by( args.delete(:discount_id) ) if args[:discount_id]
			discount ||= args[:discount]
			discount = nil unless discount.try(:for_subscriptions?)

			args[:price]		||= args[:amount] / quantity if args[:amount]
			args[:price]		||= offer.price_for_interval( interval )

			args[:amount]		||= args[:price] * quantity

			args[:currency]		||= 'USD'
			offer_schedule_interval_period	= offer.interval_period_for_interval( interval )
			offer_schedule_interval_value		= offer.interval_value_for_interval( interval )
			offer_schedule_interval_unit		= offer.interval_unit_for_interval( interval )

			puts "current_period_end_at = #{start_at} + #{offer_schedule_interval_period} (#{offer.id}, #{interval})"
			current_period_end_at = start_at + offer_schedule_interval_period

			subscription = args[:subscription] || Subscription.new()
			subscription.attributes = {
				user: user,
				offer: offer,
				billing_user_address: args[:billing_user_address],
				shipping_user_address: args[:shipping_user_address],
				billing_address: args[:billing_address],
				shipping_address: args[:shipping_address],
				quantity: quantity,
				status: 'active',
				start_at: start_at,
				current_period_start_at: start_at,
				current_period_end_at: current_period_end_at,
				next_charged_at: current_period_end_at,
				billing_interval_value: offer_schedule_interval_value,
				billing_interval_unit: offer_schedule_interval_unit,
				currency: args[:currency],
				discount: discount,
				provider: args[:provider],
				transaction_provider: args[:transaction_provider],
				merchant_identification: args[:merchant_identification],
				provider_customer_profile_reference: args[:provider_customer_profile_reference],
				provider_customer_payment_profile_reference: args[:provider_customer_payment_profile_reference],
				payment_profile_expires_at: args[:payment_profile_expires_at],
				amount: args[:amount],
				price: args[:price],
				shipping_carrier_service_id: args[:shipping_carrier_service_id],
				shipping: args[:shipping],
				tax: args[:tax],
			}

			subscription.billing_address ||= subscription.billing_user_address.try(:geo_address)
			subscription.shipping_address ||= subscription.shipping_user_address.try(:geo_address)

			if subscription.respond_to? :properties
				subscription.properties = {
					'credit_card_ending_in'	=> args[:credit_card_ending_in],
					'credit_card_brand'		=> args[:credit_card_brand],
				}
			end

			subscription.save!

			subscribe_subscription_offer( subscription, offer, {
				quantity: quantity,
				interval: interval,
				next_subscription_interval: next_subscription_interval,
			} )

			subscription
		end

		def subscribe_subscription_offer( subscription, offer, args = {} )
			quantity 					= args[:quantity] || 1
			interval 					= args[:interval] || 1
			next_subscription_interval	= args[:next_subscription_interval] || 1
			status 						= args[:status] || 'active'

			subscription_offer = subscription.subscription_offers.new(
				offer: offer,
				status: status,
				quantity: quantity,
				next_subscription_interval: next_subscription_interval,
			)

			subscription_recalculate( subscription )

			subscription.save!

			log_event( user: subscription.user, name: 'subscribed', category: 'ecom', on: subscription, content: "started a subscription #{subscription.code} to #{offer.title}" )

			subscription_offer
		end

		def subscription_change_offer( subscription, offer, args = {} )

			subscription_offer = subscription.subscription_offers.where( offer: subscription.offer ).first
			subscription_offer = subscription.subscription_offers.first if subscription_offer.blank? && subscription.subscription_offers.count == 1

			if subscription_offer.present?
				subscription_offer_change_offer( subscription_offer, offer, args )
				if subscription.subscription_offers.count == 1
					subscription.offer = offer
					subscription.save!
				end
			else
				raise Exception.new('Subscription does not have the appropriate subscription offer.')
			end

			subscription
		end

		def subscription_offer_change_offer( subscription_offer, offer, args = {} )

			subscription = subscription_offer.subscription

			subscription.offer = offer if subscription_offer.offer == subscription.offer

			old_offer = subscription_offer.offer
			subscription_offer.offer = offer
			subscription_offer.quantity = args[:quantity] if args[:quantity].present?
			subscription_offer.save!

			subscription_recalculate( subscription )
			subscription.save!

			log_event( user: subscription.user, name: 'subscription_offer_changed', category: 'ecom', on: subscription_offer, content: "changed a subscription #{subscription.code} offer from '#{old_offer.title}' to '#{offer.title}'" )

			subscription
		end

		def subscription_recalculate( subscription )

			if subscription.subscription_offers.blank?

				subscription.price = subscription.offer.price_for_interval( subscription.next_subscription_interval )
				subscription.amount = subscription.price * subscription.quantity

			else
				subscription.price = 0
				subscription.amount = 0

				subscription.subscription_offers.active.each do |subscription_offer|

					price = subscription_offer.offer.price_for_interval( subscription_offer.next_offer_interval )
					subscription.price = subscription.price + price
					subscription.amount = subscription.amount + price * subscription_offer.quantity

				end
			end

			if subscription.respond_to? :estimated_total
				order = calculate_subscription_order( subscription )

				subscription.estimated_tax = order.tax
				subscription.estimated_shipping = order.shipping
				subscription.estimated_discount = order.discount
				subscription.estimated_subtotal = order.subtotal
				subscription.estimated_total = order.total
				# subscription.estimated_interval = order.tax
				subscription.estimate_update_at = Time.now

			end

			

		end

		def generate_subscription_order( subscription, args = {} )
			generate_subscriptions_order( [subscription], args )
		end

		def generate_subscriptions_order( subscriptions, args = {} )
			time_now = args[:now] || Time.now


			order = @order_class.constantize.new(
				billing_address: subscriptions.first.billing_address,
				shipping_address: subscriptions.first.shipping_address,
				billing_user_address: subscriptions.first.billing_user_address,
				shipping_user_address: subscriptions.first.shipping_user_address,
				user: subscriptions.first.user,
				generated_by: 'system_generaged',
				parent: subscriptions.first,
				email: subscriptions.first.user.email,
				currency: subscriptions.first.currency,
				provider: subscriptions.first.provider,
				provider_customer_profile_reference: subscriptions.first.provider_customer_profile_reference,
				provider_customer_payment_profile_reference: subscriptions.first.provider_customer_payment_profile_reference,
			)

			discounts = []

			subscriptions.each do |subscription|
				# create order

				subscription_interval = args[:interval] || subscription.next_subscription_interval

				if subscription.subscription_offers.blank?
					offer = subscription.offer

					interval = args[:interval] || subscription.next_subscription_interval
					price = subscription.price_for_interval( interval )
					order.order_offers.new(
						offer: offer,
						subscription: subscription,
						price: price,
						subtotal: price * subscription.quantity,
						quantity: subscription.quantity,
						title: offer.cart_title,
						tax_code: offer.tax_code,
						subscription_interval: interval
					)
				else
					subscription.subscription_offers.to_a.each do |subscription_offer|
						if subscription_offer.active? && subscription_offer.next_subscription_interval <= subscription_interval
							offer = subscription.offer

							offer_interval = args[:offer_interval] || subscription_offer.next_offer_interval

							price = subscription_offer.offer.price_for_interval( offer_interval )
							order.order_offers.new(
								offer: offer,
								subscription: subscription,
								price: price,
								subtotal: price * subscription_offer.quantity,
								quantity: subscription_offer.quantity,
								title: offer.cart_title,
								tax_code: offer.tax_code,
								subscription_interval: subscription_interval,
								offer_interval: offer_interval,
								subscription_offer: subscription_offer,
							)
						end
					end
				end

				# apply the subscription discount to new orders, but only the first one.
				if ( discount = subscription.discount ).present?
					order.order_items.new( item: discount, order_item_type: 'discount', title: discount.title ) if discounts.blank? && discount.active? && discount.in_progress?( now: time_now ) && @order_service.discount_service.get_order_discount_errors( order, discount ).blank?
					discounts << discount
				end
			end

			order
		end

		def calculate_subscription_order( subscription, args = {} )
			order = generate_subscription_order( subscription, args = {} )
			order.status = 'draft'

			@order_service.calculate( order, shipping: get_shipping_options_from_subscription(subscription) )

			order
		end

		def calculate_subscriptions_order( subscriptions, args = {} )

			order = generate_subscriptions_order( subscriptions, args = {} )
			order.status = 'draft'

			@order_service.calculate( order, shipping: get_shipping_options_from_subscriptions(subscriptions) )

			order
		end

		def charge_subscription( subscription, args = {} )
			charge_subscriptions( [subscription], args )
		end

		def charge_subscriptions( subscriptions, args = {} )
			time_now = args[:now] || Time.now
			max_next_charged_at = args[:max_next_charged_at] || time_now

			subscription_intervals = {}
			subscriptions.each do |subscription|
				raise Exception.new("Subscription #{subscription.id } isn't ready to renew yet.  Currently it's #{time_now}, but subscription doesn't renew until #{subscription.next_charged_at}") unless subscription.next_charged_at < max_next_charged_at
				raise Exception.new("Subscription #{subscription.id } isn't active, so can't be charged.") unless subscription.active?

				subscription_intervals[subscription.id] = subscription.next_subscription_interval
			end

			order = generate_subscriptions_order( subscriptions, args.merge( now: time_now ) )


			# process order
			begin

				transaction = @order_service.process( order, shipping: get_shipping_options_from_subscriptions(subscriptions))

			rescue Exception => e

				subscriptions.each do |subscription|
					subscription.failed_attempts = subscription.failed_attempts + 1 if subscription.respond_to? :failed_attempts
					subscription.failed_message = "Exception: #{e.message}" if subscription.respond_to? :failed_message
					subscription.failed_at = Time.now if subscription.respond_to? :failed_at

					# mark subscription as failed if the transaction failed
					subscription.status = 'failed'

					subscription.save

					log_event( name: 'subscription_failed', category: 'ecom', on: subscription, content: "subscription #{subscription.code} failed to renew due to: #{subscription.failed_message}" )
				end

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

					transaction.parent_obj = subscriptions.first
					transaction.save

				else

					# if no transaction was created, create one to log the error
					transaction = Bazaar::Transaction.create(
						message: order.nested_errors.join(' * '),
						parent_obj: subscriptions.first,
						status: 'declined',
						transaction_type: 'charge',
						amount: order.total,
						currency: order.currency,
					)

				end

				subscriptions.each do |subscription|
					# annotate how, how often, and when the subscription failed
					subscription.failed_attempts = subscription.failed_attempts + 1 if subscription.respond_to? :failed_attempts
					subscription.failed_message = transaction.message if subscription.respond_to? :failed_message
					subscription.failed_at = transaction.created_at if subscription.respond_to? :failed_at

					# mark subscription as failed if the transaction failed
					subscription.status = 'failed'

					subscription.save
				end

				order.errors.add(:base, :processing_error, message: 'Transaction failed') if !transaction || not( transaction.approved? )

			else
				order.save

				subscriptions.each do |subscription|
					subscription_interval = subscription_intervals[subscription.id]

					log_event( user: subscription.user, name: 'renewal', on: subscription, content: "auto renewed a subscription #{subscription.code}" )

					# remove discount after use, if it is not for more than one order
					subscription.discount = nil unless subscription.discount.try(:for_subscriptions?)

					subscription.failed_attempts = 0 if subscription.respond_to? :failed_attempts

					# @todo don't change billing interval if customer has updated it
					if ( interval_value = subscription.interval_value_for_interval( subscription_interval ) ).present?
						subscription.billing_interval_value	= interval_value
						subscription.billing_interval_unit	= subscription.interval_unit_for_interval( subscription_interval )
					end

					# update the subscriptions next date
					update_next_charged_at( subscription )

					subscription.save

				end

			end

			order

		end

		def update_next_charged_at( subscription )
			subscription.current_period_start_at = Time.now
			subscription.current_period_end_at = subscription.current_period_start_at + subscription.billing_interval
			subscription.next_charged_at = subscription.current_period_end_at
		end

		def update_payment_profile( subscription, args = {} )
			@order_service.transaction_service.update_subscription_payment_profile( subscription, args )
		end



		def get_shipping_options_from_subscription(subscription)
			{ shipping_carrier_service_id: subscription.shipping_carrier_service_id, fixed_price: subscription.shipping }
		end

		def get_shipping_options_from_subscriptions(subscriptions)
			# if all subscriptions have fixed price shipping, then sum them up.
			fixed_price_shipping = subscriptions.sum(&:shipping) unless subscriptions.select{|sub| sub.shipping.nil? }.present?

			shipping_carrier_service_id = subscriptions.collect(&:shipping_carrier_service_id).select(&:present?).first

			{
				shipping_carrier_service_id: shipping_carrier_service_id,
				fixed_price: fixed_price_shipping,
			}
		end

	end


end
