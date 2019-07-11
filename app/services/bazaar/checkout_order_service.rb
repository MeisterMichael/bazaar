module Bazaar

	class CheckoutOrderService < Bazaar::OrderService

		def calculate_order_status( order, args = {} )
			order_status = order.status
			order_status = 'pre_order' if order.order_offers.select{|order_offer| order_offer.offer.pre_order? || order_offer.offer.backorder? }.present? || order.order_items.select{|order_item| order_item.prod? && order_item.item.offer.pre_order? }.present?
			order_status.to_s
		end

	end

end
