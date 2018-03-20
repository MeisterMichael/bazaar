# a list of tax codes
# https://taxcloud.net/tic/

module SwellEcom

	class DiscountService

		def initialize( args = {} )
		end

		def calculate( obj, args = {} )

			return self.calculate_order( obj, args ) if obj.is_a? Order
			return self.calculate_cart( obj, args ) if obj.is_a? Cart

		end

		protected

		def calculate_discount_amount( discount_order_item, order, args = {} )
			discount = discount_order_item.item
			discount_items = args[:discount_items] || discount.discount_items
			amount = 0


			discount_items.each do |discount_item|
				order_items = order.order_items.to_a

				order_items = order_items.select{ |order_item| not( order_item.discount? ) }
				order_items = order_items.select{ |order_item| order_item.order_item_type == discount_item.order_item_type } unless discount_item.all_order_item_types?
				order_items = order_items.select{ |order_item| order_item.item.is_a?( Subscription ) && order_item.item.orders.not_declined.count >= discount_item.minimum_orders } if discount_item.minimum_orders > 0
				order_items = order_items.select{ |order_item| not( order_item.item.is_a?( Subscription ) ) || OrderItem.discount.joins(:order).merge( order_item.item.orders.not_declined ).where( item_id: discount_item.discount, item_type: discount_item.discount.class.base_class.name ).count < discount_item.maximum_orders } unless discount_item.maximum_orders.to_i <= 1

				if discount_item.applies_to.is_a?( SwellEcom::Collection )

					items = discount_item.applies_to.items
					order_items = order_items.select{ |order_item| items.include?( order_item.item ) }

				elsif discount_item.applies_to.is_a?( Product ) || discount_item.applies_to.is_a?( SubscriptionPlan )

					order_items = order_items.select{ |order_item| order_item.item == discount_item.applies_to }

				elsif discount_item.applies_to.present?
					raise Exception.new('Unsupported discount_item.applies_to')
				end

				if discount_item.percent?
					subtotal = order_items.sum{ |order_item| order_item.subtotal }
					amount = amount + ( subtotal * discount_item.discount_amount / 100.0 ).round
				elsif discount_item.fixed?
					amount = amount + discount_item.discount_amount if order_items.present?
				elsif discount_item.fixed_each?
					amount = amount + discount_item.discount_amount * order_items.sum{|order_item| order_item.quantity }
				else
					raise Exception.new('Unsupported discount_item.discount_type')
				end


			end

			amount
		end

		def calculate_cart( cart, args = {} )
			# @todo
		end

		def calculate_order( order, args = {} )
			discount_order_items = order.order_items.select{ |order_item| order_item.discount? }
			discount_order_items = discount_order_items.select{ |order_item| order_item.item.minimum_tax_subtotal == 0 } if args[:pre_tax]

			discount_order_items.each do |order_item|
				order_item.subtotal = 0
			end

			return false unless validate_order_discounts( order, discount_order_items )

			discount_order_items.each do |order_item|
				discount_amount = calculate_discount_amount( order_item, order )
				order_item.subtotal = -discount_amount
			end

			order.discount = -order.order_items.select(&:discount?).sum(&:subtotal)

		end

		def validate_order_discounts( order, discount_order_items, args = {} )
			discount_order_items.each do |discount_order_item|
				validate_order_discount( order, discount_order_item, args )
			end

			return order.errors.blank?
		end

		def validate_order_discount( order, discount_order_item, args = {} )
			discount = discount_order_item.item

			prod_order_items		= order.order_items.select{ |order_item| order_item.prod? }
			shipping_order_items	= order.order_items.select{ |order_item| order_item.shipping? }
			tax_order_items			= order.order_items.select{ |order_item| order_item.tax? }

			order.errors.add( :base, :discount_error, message: 'Invalid discount' ) if not( discount.active? ) || not( discount.in_progress? )
			order.errors.add( :base, :discount_error, message: 'Unsupported discount type' ) if discount.selected_users?
			order.errors.add( :base, :discount_error, message: 'Does not meet minimum purchase requirement' ) if discount.minimum_prod_subtotal != 0 && discount.minimum_prod_subtotal > prod_order_items.sum{ |order_item| order_item.subtotal }
			order.errors.add( :base, :discount_error, message: 'Does not meet minimum shipping requirement' ) if discount.minimum_shipping_subtotal != 0 && discount.minimum_shipping_subtotal > shipping_order_items.sum{ |order_item| order_item.subtotal }
			order.errors.add( :base, :discount_error, message: 'Does not meet minimum tax requirement' ) if discount.minimum_tax_subtotal != 0 && discount.minimum_tax_subtotal > tax_order_items.sum{ |order_item| order_item.subtotal }
			order.errors.add( :base, :discount_error, message: 'You have exceeded the limit of uses for the selected discount' ) if discount.limit_per_customer.present? && order.user.present? && OrderItem.where( item: discount ).joins(:order).merge( Order.where( user: order.user ) ).count >= discount.limit_per_customer
			order.errors.add( :base, :discount_error, message: 'The selected discount\'s usage limit has been exhausted' ) if discount.limit_global.present? && OrderItem.where( item: discount ).count >= discount.limit_global

			return order.errors.blank?
		end

	end

end
