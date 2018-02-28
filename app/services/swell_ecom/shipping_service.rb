module SwellEcom

	class ShippingService

		def initialize( args = {} )
			@multiplier_adjustment = 1.00 + ( ( args[:percent_adjustment] || 0 ).to_f / 100.00 )
			@flat_adjustment = args[:flat_adjustment] || 0

			@code_whitelist = args[:code_whitelist]
			@code_blacklist = args[:code_blacklist]

			@name_whitelist = args[:name_whitelist]
			@name_blacklist = args[:name_blacklist]
		end

		def calculate( obj, args = {} )
			return self.calculate_order( obj, args ) if obj.is_a? Order
			return self.calculate_cart( obj, args ) if obj.is_a? Cart
		end

		def fetch_delivery_status( order, args = {} )
			fetch_delivery_status_for_code( order.tracking_number, args )
		end

		def fetch_delivery_status_for_code( code, args = {} )
			# @todo
		end

		def find_rates( obj, args = {} )
			return self.find_order_rates( obj, args ) if obj.is_a? Order
			return self.find_cart_rates( obj, args ) if obj.is_a? Cart
		end

		def process( order, args = {} )
			# @todo
		end

		def validate( geo_address )
			# @todo
			not( geo_address.errors.present? )
		end

		protected

		def calculate_cart( cart, args = {} )
			rates = find_cart_rates( cart, args )
			rate = find_default_rate( rates )

			if rate.present?
				cart.update( estimated_shipping: rate[:price] )
			else
				cart.update( estimated_shipping: 0 )
			end
		end

		def calculate_order( order, args={} )
			return false unless order.shipping_address.validate
			rates = find_order_rates( order, args ).sort_by{ |rate| rate[:price] }

			if args[:rate_code].present?
				rate = rates.select{ |rate| rate[:code] == args[:rate_code] }.first
			elsif args[:rate_name].present?
				rate = rates.select{ |rate| rate[:name] == args[:rate_name] }.first
			else
				rate = find_default_rate( rates )
			end

			if rate.present?
				order.order_items.new( item: nil, price: rate[:price], subtotal: rate[:price], title: rate[:name], order_item_type: 'shipping', tax_code: '11000', properties: { 'code' => rate[:code], 'carrier' => rate[:carrier] } )
				order.shipping = rate[:price]
			else
				order.shipping = 0
			end
		end

		def find_cart_rates( cart, args = {} )
			return [] unless args[:ip_country].present?
			country = SwellEcom::GeoCountry.find_by( abbrev: args[:ip_country].upcase )
			return [] unless country.present?

			address = SwellEcom::GeoAddress.new( geo_country: country )

			find_address_rates( address, cart.cart_items, args )
		end

		def find_default_rate( rates )
			rate = rates.sort_by{ |rate| rate[:price] }.first
		end

		def find_order_rates( order, args = {} )
			find_address_rates( order.shipping_address, order.order_items.select{ |order_item| order_item.prod? }, args )
		end

		def find_address_rates( geo_address, line_items, args = {} )
			cache_key = geo_address.attributes.to_json
			cache_key = cache_key + line_items.collect(&:attributes).to_json

			Rails.cache.fetch("swell_ecom/shipping_service/#{cache_key}", expires_in: 10.minutes) do

				rates = request_address_rates( geo_address, line_items, args )

				rates = rates.select{ |rate| @code_whitelist.include?( rate[:code] ) } if @code_whitelist.present?
				rates = rates.select{ |rate| not( @code_blacklist.include?( rate[:code] ) ) } if @code_blacklist.present?
				rates = rates.select{ |rate| @name_whitelist.include?( rate[:name] ) } if @name_whitelist.present?
				rates = rates.select{ |rate| not( @name_blacklist.include?( rate[:name] ) ) } if @name_blacklist.present?

				rates.each do |rate|
					rate[:price] = (rate[:price] * @multiplier_adjustment + @flat_adjustment).round()
				end

				rates

		    end
		end

		def request_address_rates( geo_address, line_items, args = {} )
			[]
		end

	end

end
