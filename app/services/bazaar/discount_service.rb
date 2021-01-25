# a list of tax codes
# https://taxcloud.net/tic/

module Bazaar

	class DiscountService < ::ApplicationService

		def initialize( args = {} )
		end

		def calculate_pre_tax( obj, args = {} )

			return self.calculate_order_pre_tax( obj, args ) if obj.is_a? Order
			return self.calculate_cart_pre_tax( obj, args ) if obj.is_a? Cart

		end
		def calculate_post_tax( obj, args = {} )

			return self.calculate_order_post_tax( obj, args ) if obj.is_a? Order
			return self.calculate_cart_post_tax( obj, args ) if obj.is_a? Cart

		end

		def get_order_discount_errors( order, discount, args = {} )

			prod_order_offers		= order.order_offers.to_a
			shipping_order_items	= order.order_items.select{ |order_item| order_item.shipping? }
			tax_order_items			= order.order_items.select{ |order_item| order_item.tax? }

			all_not_self_positive_status_orders = Order.positive_status.where.not( id: order.id )
			all_discount_order_items = OrderItem.where( item: discount ).joins(:order)

			error_messages = []
			error_messages << 'Invalid discount' if not( discount.active? ) || not( discount.in_progress? )
			error_messages << 'Unsupported discount type' if discount.selected_users?
			error_messages << 'The discount does not meet the minimum purchase requirement' if discount.minimum_prod_subtotal != 0 && discount.minimum_prod_subtotal > prod_order_offers.sum(&:subtotal)
			error_messages << 'The discount does not meet the minimum shipping requirement' if discount.minimum_shipping_subtotal != 0 && discount.minimum_shipping_subtotal > shipping_order_items.sum{ |order_item| order_item.subtotal }
			error_messages << 'The discount does not meet the minimum tax requirement' if discount.minimum_tax_subtotal != 0 && discount.minimum_tax_subtotal > tax_order_items.sum{ |order_item| order_item.subtotal }
			error_messages << 'You have exceeded the limit of uses for the selected discount' if discount.limit_per_customer.present? && order.user.present? && all_discount_order_items.merge( all_not_self_positive_status_orders.where( user: order.user ) ).count >= discount.limit_per_customer
			error_messages << 'The selected discount\'s usage limit has been exhausted' if discount.limit_global.present? && all_discount_order_items.merge( all_not_self_positive_status_orders ).count >= discount.limit_global

			error_messages
		end

		def recalculate_pre_tax( obj, args = {} )

			return self.calculate_order_pre_tax( obj, args.merge( recalculate: true ) ) if obj.is_a? Order
			return self.calculate_cart_pre_tax( obj, args ) if obj.is_a? Cart

		end
		def recalculate_post_tax( obj, args = {} )

			return self.calculate_order_post_tax( obj, args ) if obj.is_a? Order
			return self.calculate_cart_post_tax( obj, args ) if obj.is_a? Cart

		end

		def validate( order, args = {} )
			validate_order_discounts( order, order.order_items.select(&:discount?), args )
		end

		protected

		def calculate_discount_amount( discount_order_item, order, args = {} )
			discount = discount_order_item.item
			discount_items = args[:discount_items] || discount.discount_items
			amount = 0

			return 0 if order.subscription_renewal? && discount.non_recurring_orders?

			quantity_remaining = Float::INFINITY
			if discount.maximum_units_per_customer.to_i > 0
				order_user = order.user
				order_user ||= User.find_by( email: order.email.downcase ) if order.email.present?

				if order_user.present?
					quantity_used = Bazaar::OrderOfferDiscount.where( order: order_user.orders.positive_status, discount: discount ).sum(:quantity).to_i

					quantity_remaining = discount.maximum_units_per_customer
					quantity_remaining = quantity_remaining - quantity_used
					quantity_remaining = 0 if quantity_remaining < 0
				end
			end


			discount_items.each do |discount_item|
				order_items = order.order_items.to_a

				# Order items should not include products or discounts, leaving only
				# tax and shipping. If the discount item does not include ALL order item
				# types, then filter out any that do not match the selected order item
				# type.
				order_items = order_items.select{ |order_item| order_item.tax? || order_item.shipping? }
				order_items = order_items.select{ |order_item| order_item.order_item_type == discount_item.order_item_type } unless discount_item.all_order_item_types?

				# A list of order offers that have discounts applied to them for this
				order_offer_discounts = []

				# if filter type includes product offers then search them for qualifying
				# offers, creating a list of order offer discounts
				if discount_item.all_order_item_types? || discount_item.prod?

					# sort by most expensive first, so that discounts are applied to the
					# customer's benefit
					order_offers = order.order_offers.to_a.sort_by(&:price).reverse

					order_offers.each do |order_offer|
						keep = true

						if ( subscription = order_offer.subscription ).is_a?( Subscription )
							this_discount_order_items = OrderItem.discount.joins(:order).merge( subscription.orders.not_declined.where.not( id: order.id ) ).where( item: discount_item.discount )

							keep = false if discount_item.minimum_orders.to_i > 0 || discount_item.maximum_orders.to_i > 1
							keep = keep || (this_discount_order_items.count >= discount_item.minimum_orders) if discount_item.minimum_orders.to_i > 0
							keep = keep || (this_discount_order_items.count < discount_item.maximum_orders) if discount_item.maximum_orders.to_i > 1
						elsif order_offer.subscription_interval == 1 && discount_item.minimum_orders.to_i > 0
							keep = false
						end

						if keep
							quantity = [ quantity_remaining, order_offer.quantity ].min

							if quantity > 0
								order_offer_discount = order_offer.order_offer_discounts.new( discount: discount, quantity: quantity, offer: order_offer.offer, order: order_offer.order, user: order_offer.order.user )

								# duduct the quantity used from quantity available/remaining.
								quantity_remaining = quantity_remaining - quantity
								order_offer_discounts << order_offer_discount
							end
						end
					end
				end

				if discount_item.applies_to.is_a?( Bazaar::Collection )

					offers = []
					discount_item.applies_to.items.each do |item|
						if item.is_a? Bazaar::Offer
							offers << item
						elsif item.respond_to? :offer
							offers << item.offer
						else
							raise Exception.new("Unable to find offer for #{item.class.name}\##{item.id}")
						end
					end
					offers = offers.uniq

					order_offer_discounts = order_offer_discounts.select{ |order_offer_discount| offers.include?( order_offer_discount.offer ) }

				elsif discount_item.applies_to.is_a? Bazaar::Offer

					order_offer_discounts = order_offer_discounts.select{ |order_offer_discount| order_offer_discount.offer == discount_item.applies_to }

				elsif discount_item.applies_to.respond_to?( :offer )

					order_offer_discounts = order_offer_discounts.select{ |order_offer_discount| order_offer_discount.offer == discount_item.applies_to.offer }

				elsif discount_item.applies_to.present?
					raise Exception.new('Unsupported discount_item.applies_to')
				end

				if discount_item.percent?
					subtotal = order_items.to_a.sum(&:subtotal) + order_offer_discounts.sum{ |order_offer_discount| order_offer_discount.quantity * order_offer_discount.order_offer.price }
					amount = amount + ( subtotal * discount_item.discount_amount / 100.0 ).round
				elsif discount_item.fixed?
					amount = amount + discount_item.discount_amount if order_items.present? || order_offer_discounts.present?
				elsif discount_item.fixed_each?
					amount = amount + discount_item.discount_amount * order_offer_discounts.sum{|order_item| order_item.quantity }
				else
					raise Exception.new('Unsupported discount_item.discount_type')
				end


			end

			amount
		end

		def calculate_cart_pre_tax( cart, args = {} )
			# @todo
		end

		def calculate_cart_post_tax( cart, args = {} )
			# @todo
		end

		def calculate_order_discounts( order, args = {} )
			Bazaar::PromotionDiscount.active.in_progress.each do |discount|
				order.order_items.new( item: discount, order_item_type: 'discount', title: discount.title )
			end

			Bazaar::Discount.pluck('distinct type').collect(&:constantize) if Rails.env.development?
			discount = Bazaar::CouponDiscount.active.in_progress.where( 'lower(code) = ?', args[:code].downcase.strip ).first if args[:code].present?
			order.order_items.new( item: discount, order_item_type: 'discount', title: discount.title ) if discount.present?
		end

		def calculate_order_pre_tax( order, args = {} )

			# calculate any discounts that need to be added
			calculate_order_discounts( order, args ) unless args[:recalculate]

			# calculate the discount amount, pre tax so appropriate taxes can be applied net of discount
			discount_order_items = order.order_items.to_a.select(&:discount?).select{ |order_item| order_item.item.minimum_tax_subtotal.to_i == 0 }
			calculate_order( order, discount_order_items, args )

		end

		def calculate_order_post_tax( order, args = {} )
			# re-calculate the discount amounts, post tax so that it can include taxes discounts
			discount_order_items = order.order_items.to_a.select(&:discount?)
			calculate_order( order, discount_order_items, args )
		end

		def calculate_order( order, discount_order_items, args = {} )

			order.discount = 0

			discount_order_items.each do |order_item|
				order_item.subtotal = 0
			end

			order.order_offers.to_a.each do |order_offer|
				order_offer.order_offer_discounts = []
			end

			return false unless validate_order_discounts( order, discount_order_items )

			discount_order_items.each do |order_item|
				discount_amount = calculate_discount_amount( order_item, order )
				order_item.subtotal = -discount_amount
			end

			order.discount = -discount_order_items.sum(&:subtotal)

		end

		def validate_order_discounts( order, discount_order_items, args = {} )
			discount_order_items.each do |discount_order_item|
				error_messages = get_order_discount_errors( order, discount_order_item.item, args )
				error_messages.each do |error_message|
					order.errors.add( :base, :discount_error, message: error_message )
				end
			end

			return order.errors.blank?
		end

	end

end
