module SwellEcom

	class ShippingService

		def initialize( args = {} )
		end

		def calculate( obj, args = {} )

			return self.calculate_order( obj, args ) if obj.is_a? Order
			return self.calculate_cart( obj, args ) if obj.is_a? Cart

		end


		protected

		def calculate_cart( cart, args = {} )

			cart.update estimated_shipping: 0

		end

		def calculate_order( order, args={} )
			service_name = args[:service_name]
			rates = find_order_rates( order ).sort_by{ |rate| rate[:price] }

			rate = rates.select{ |rate| rate.service_name == service_name }.first if service_name.present?
			rate ||= rates.first

			order.order_items.new( item: nil, price: rate[:price], subtotal: rate[:price], title: 'Shipping', order_item_type: 'shipping', tax_code: '11000', properties: { 'service_name' => rate[:name], 'carrier' => rate[:carrier] } ) if rate.present?

		end

		def find_order_rates( order )
			find_rates( order.shipping_address, order.order_items.select{ |order_item| order_item.prod? } )
		end

		def find_rates( geo_address, line_items )
			[]
		end

		def process( order, args = {} )

		end

	end

end
