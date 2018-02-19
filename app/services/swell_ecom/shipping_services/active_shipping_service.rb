
require 'active_shipping'


module SwellEcom

	module ShippingServices

		class ActiveShippingService < SwellEcom::ShippingService

			def initialize( args = {} )

				warehouse_address = args[:warehouse] || SwellEcom.warehouse_address
				@origin = ActiveShipping::Location.new(
					country: warehouse_address[:country],
					state: warehouse_address[:state],
					city: warehouse_address[:city],
					zip: warehouse_address[:zip],
				)

				args[:class]	||= 'ActiveShipping::USPS'
				args[:config]	||= { login: '964NEURO4822' }

				@code_whitelist = args[:code_whitelist]

				@shipping_service = args[:class].constantize.new( args[:config] )

			end

			def calculate_cart( cart, args={} )

				cart.update estimated_shipping: 0

			end

			def calculate_order( order, args={} )
				service_name = args[:service_name]
				rates = find_order_rates( order ).sort_by{ |rate| rate[:price] }

				rate = rates.select{ |rate| rate.service_name == service_name }.first if service_name.present?
				rate ||= rates.first

				price = rate[:price]
				price = (price * 100).to_i unless price.is_a? Integer

				order.order_items.new item: nil, price: price, subtotal: price, title: 'Shipping', order_item_type: 'shipping', tax_code: '11000', properties: { 'service_name' => rate[:name] }

			end

			def find_order_rates( order )
				find_rates( order.shipping_address, order.order_items.select{ |order_item| order_item.prod? } )
			end

			def find_rates( geo_address, line_items )
				packages = []

				line_items.each do |line_item|
					item = line_item.item
					item = item.subscription_plan if item.is_a? SwellEcom::Subscription

					if item.present? && item.respond_to?(:package_shape) && not( item.no_package? )

						[1..line_item.quantity].each do |i|
							if item.cylinder?
								packages << ActiveShipping::Package.new(
									  item.package_weight,
									  [ item.package_length, item.package_width ],
									  cylinder: true	# cylinders have different volume calculations
								  )
							else
								packages << ActiveShipping::Package.new(
									item.package_weight,
									[ item.package_height, item.package_width, item.package_length ],
								)
							end
						end
					end
				end

				destination = ActiveShipping::Location.new(
					country: geo_address.geo_country.abbrev,
					province: geo_address.state_abbrev,
					city: geo_address.city,
					zip: geo_address.zip
				)

				response = @shipping_service.find_rates( @origin, destination, packages )

				rates = response.rates.collect do |rate|
					{ name:	rate.service_name, code: rate.service_code, price: rate.total_price, carrier: rate.carrier, currency: rate.currency }
				end

				rates = rates.select{ |rate| @code_whitelist.include? rate[:code] } if @code_whitelist.present?

				rates
			end

			def process( order, args = {} )

			end

		end

	end

end
