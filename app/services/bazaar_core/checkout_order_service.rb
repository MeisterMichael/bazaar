module Bazaar

	class CheckoutOrderService < Bazaar::OrderService

		def calculate_order_status( order, args = {} )
			order_status = order.status
			order_status = 'pre_order' if order.has_pre_order_offers? || order.has_backorder_offers?
			order_status.to_s
		end

	end

end
