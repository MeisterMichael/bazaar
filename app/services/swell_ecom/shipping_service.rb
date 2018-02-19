module SwellEcom

	class ShippingService

		def initialize( args = {} )
			@multiplier_adjustment = 1.00 + ( ( args[:percent_adjustment] || 0 ).to_f / 100.00 )
			@flat_adjustment = args[:flat_adjustment] || 0

			@code_whitelist = args[:code_whitelist]
			@code_blacklist = args[:code_blacklist]
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

			rate = rates.select{ |rate| rate[:service_name] == service_name }.first if service_name.present?
			rate ||= rates.first

			order.order_items.new( item: nil, price: rate[:price], subtotal: rate[:price], title: 'Shipping', order_item_type: 'shipping', tax_code: '11000', properties: { 'service_name' => rate[:name], 'carrier' => rate[:carrier] } ) if rate.present?

		end

		def find_order_rates( order )
			find_rates( order.shipping_address, order.order_items.select{ |order_item| order_item.prod? } )
		end

		def find_rates( geo_address, line_items )
			rates = request_shipping_rates( geo_address, line_items )

			rates = rates.select{ |rate| @code_whitelist.include?( rate[:code] ) } if @code_whitelist.present?
			rates = rates.select{ |rate| not( @code_blacklist.include?( rate[:code] ) ) } if @code_blacklist.present?

			rates.each do |rate|
				rate[:price] = rate[:price] * @multiplier_adjustment + @flat_adjustment
			end

			rates
		end

		def process( order, args = {} )
			# @todo
		end

		protected
		def request_shipping_rates( geo_address, line_items )
			[]
		end

	end

end
