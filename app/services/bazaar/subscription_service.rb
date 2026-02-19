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

					order_offer.offer_interval = order_offer.offer_interval || 1
					order_offer.subscription_offer = self.subscribe_for_subscription_offer( order.user, order_offer.offer, args.merge( quantity: order_offer.quantity, order: order, subscription: order_offer.subscription, interval: order_offer.offer_interval ) )
					order_offer.subscription = order_offer.subscription_offer.subscription

					order_offer.save

				end
			end

		end

		def subscribe( user, offer, args = {} )
			subscription_offer = subscribe_for_subscription_offer( user, offer, args )

			subscription_offer.subscription
		end

		def subscribe_for_subscription_offer( user, offer, args = {} )
			start_at 					= args[:start_at] || Time.now
			quantity 					= args[:quantity] || 1
			interval 					= args[:interval] || 1
			next_subscription_interval	= args[:next_subscription_interval] || 2

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
				args[:provider_customer_payment_profile_options] ||= order.provider_customer_payment_profile_options
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
				provider_customer_payment_profile_options: args[:provider_customer_payment_profile_options],
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

			subscription_offer = subscribe_subscription_offer( subscription, offer, {
				quantity: quantity,
				interval: interval,
				next_subscription_interval: next_subscription_interval,
			} )

			subscription_offer
		end

		def subscribe_subscription_offer( subscription, offer, args = {} )
			quantity 					= args[:quantity] || 1
			interval 					= args[:interval] || 1
			next_subscription_interval	= args[:next_subscription_interval] || 2
			status 						= args[:status] || 'active'

			subscription_offer = subscription.subscription_offers.new(
				offer: offer,
				status: status,
				quantity: quantity,
				next_subscription_interval: next_subscription_interval,
			)

			subscription_offer.save!
			subscription.save!

			subscription_recalculate( subscription )

			subscription.save!

			subscription.subscription_logs.create( subject: 'Subscribed', details: "started a subscription" )
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

			subscription.save!

			subscription_recalculate( subscription )

			subscription.save!

			subscription.subscription_logs.create( subject: 'Subscription Offer Changed', details: "changed a subscription #{subscription.code} offer from '#{old_offer.title}' to '#{offer.title}'" )
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
				provider_customer_payment_profile_options: subscriptions.first.provider_customer_payment_profile_options,
			)

			discounts = []

			subscriptions.each do |subscription|
				# create order

				subscription_interval = args[:interval] || subscription.next_subscription_interval

				if subscription.subscription_offers.blank?
					offer = subscription.offer

					interval = args[:interval] || subscription.next_subscription_interval
					price = subscription.price_for_interval( interval )
					order_offer = order.order_offers.new(
						offer: offer,
						subscription: subscription,
						price: price,
						subtotal: price * subscription.quantity,
						quantity: subscription.quantity,
						title: offer.cart_title,
						tax_code: offer.tax_code,
						subscription_interval: interval
					)

					order_offer.renewal_attempt = subscription.failed_attempts + 1 if order_offer.respond_to? :renewal_attempt

				else
					subscription.subscription_offers.to_a.each do |subscription_offer|
						if subscription_offer.active? && subscription_offer.next_subscription_interval <= subscription_interval
							offer = subscription_offer.offer

							offer_interval = args[:offer_interval] || subscription_offer.next_offer_interval

							price = subscription_offer.offer.price_for_interval( offer_interval )
							order_offer = order.order_offers.new(
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

							order_offer.renewal_attempt = subscription.failed_attempts + 1 if order_offer.respond_to? :renewal_attempt
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

					subscription.subscription_logs.create( subject: 'Subscription Renewal Failed', details: "failed to renew due to: #{subscription.failed_message}" )
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

					subscription.subscription_logs.create( subject: 'Subscription Renewal Processed', details: "auto renewed a subscription" )
					log_event( user: subscription.user, name: 'renewal', on: subscription, content: "auto renewed a subscription #{subscription.code}" )

					# remove discount after use, if it is not for more than one order
					subscription.discount = nil unless subscription.discount.try(:for_subscriptions?)

					subscription.failed_attempts = 0 if subscription.respond_to? :failed_attempts

					# @todo don't change billing interval if customer has updated it
					if ( interval_value = subscription.interval_value_for_interval( subscription_interval ) ).present?
						subscription.billing_interval_value	= interval_value
						subscription.billing_interval_unit	= subscription.interval_unit_for_interval( subscription_interval )
					end

					order.order_offers.where( subscription: subscription ).each do |order_offer|
						order_offer.subscription_offer.update(
							next_subscription_interval: subscription.next_subscription_interval,
						)
					end

					# update the subscriptions next date
					update_next_charged_at( subscription )

					subscription.save

					subscription_recalculate( subscription )

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

		# Merge multiple subscriptions into one by moving all subscription_offers
		# from source subscriptions into a single destination subscription.
		#
		# @param subscriptions [Array<Bazaar::Subscription>] subscriptions to merge (must share same provider/address/interval attributes)
		# @param args [Hash] options
		# @option args [String] :version version tag for audit logs (default "1.0")
		# @option args [Bazaar::Subscription] :dest_subscription force a specific destination (default: closest to average next_charged_at)
		# @return [Bazaar::Subscription] the destination subscription with merged offers
		def amalgamate_subscriptions( subscriptions, args = {} )
			version = args[:version] || "1.0"

			raise ArgumentError, "Need at least 2 subscriptions to amalgamate" if subscriptions.size < 2

			# Select destination subscription: closest next_charged_at to the group average
			dest_subscription = args[:dest_subscription]
			unless dest_subscription
				average_next_charged_at = Time.at( subscriptions.map(&:next_charged_at).map(&:to_f).sum / subscriptions.size.to_f )
				dest_subscription = subscriptions.min_by { |s| (s.next_charged_at.to_f - average_next_charged_at.to_f).abs }
			end

			source_subscriptions = subscriptions.reject { |s| s.id == dest_subscription.id }

			ActiveRecord::Base.transaction do

				dest_subscription.subscription_logs.create( "subject" => "Amalgamation Started" )

				source_subscriptions.each do |source_subscription|
					source_subscription.subscription_logs.create( "subject" => "Amalgamation Started" )

					# Move each subscription offer to the destination
					source_subscription.subscription_offers.each do |subscription_offer|

						source_subscription.subscription_logs.create(
							"subject" => "Subscription Offer \##{subscription_offer.id} Amalgamation Started",
							subscription_offer: subscription_offer,
							properties: { subscription_offer_attributes: subscription_offer.attributes }
						)

						next_subscription_interval_delta = subscription_offer.next_subscription_interval - subscription_offer.subscription.next_subscription_interval

						subscription_offer.subscription = dest_subscription
						subscription_offer.next_subscription_interval = dest_subscription.next_subscription_interval + next_subscription_interval_delta
						subscription_offer.save!

						source_subscription.subscription_logs.create( "subject" => "Subscription Offer \##{subscription_offer.id} Amalgamation Complete", subscription_offer: subscription_offer )

						source_subscription.subscription_logs.create(
							subscription_offer: subscription_offer,
							"event_type" => 'subscription_offer_amalgamated',
							"subject" => "Subscription Offer \##{subscription_offer.id} was Transfered to Subscription #{dest_subscription.code}",
							"details" => "This subscription offer was transfered from subscription #{source_subscription.code} to subscription #{dest_subscription.code}.",
							"properties" => {
								'amalgamated_to_subscription_id' => dest_subscription.id,
								'amalgamated_version' => version,
							}
						)
					end

					# Trash the source subscription
					source_subscription.status = 'trash'
					source_subscription.save!

					source_subscription.subscription_logs.create( "subject" => "Amalgamation Complete" )

					source_subscription.subscription_logs.create(
						"event_type" => 'subscription_amalgamated',
						"subject" => "Amalgamated into #{dest_subscription.code}",
						"details" => "This subscription's 'Subscription Offers' were transfered to another subscription (#{dest_subscription.code}), and then this subscription was set to the trash status.",
						"properties" => {
							'amalgamated_to_subscription_id' => dest_subscription.id,
							'amalgamated_version' => version,
						}
					)
				end

				# Recalculate the destination subscription estimates
				subscription_recalculate( dest_subscription )
				dest_subscription.save!

				dest_subscription.subscription_logs.create( "subject" => "Amalgamation Complete" )

				dest_subscription.subscription_logs.create(
					"event_type" => 'subscriptions_amalgamated',
					"subject" => "Subscriptions Amalgamated",
					"details" => "The following subscriptions had their subscription offers transfered to this subscription, and then were trashed: #{source_subscriptions.collect(&:code)}",
					"properties" => {
						'amalgamated_version' => version,
						'amalgamated_subscription_ids' => source_subscriptions.collect(&:id),
					}
				)

			end

			dest_subscription
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
