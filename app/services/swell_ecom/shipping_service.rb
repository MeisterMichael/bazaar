module SwellEcom

	class ShippingService

		def self.calculate( order )

			order.order_items.new item: nil, amount: 1000, label: 'Shipping', order_item_type: 'shipping'

			return

		end

	end

end
