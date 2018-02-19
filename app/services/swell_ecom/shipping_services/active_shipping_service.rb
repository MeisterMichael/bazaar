
require 'active_shipping'
# Gem requirements
# => gem 'active_shipping'
#
# Active Shipping Integrates with:
# => UPS (< 2.1)
# => USPS
# => USPS Returns
# => FedEx
# => Canada Post
# => New Zealand Post
# => Shipwire
# => Stamps
# => Kunaki
# => Australia Post

module SwellEcom

	module ShippingServices

		class ActiveShippingService < SwellEcom::ShippingService

			def initialize( args = {} )
				super( args )

				warehouse_address = args[:warehouse] || SwellEcom.warehouse_address
				@origin = ActiveShipping::Location.new(
					country: warehouse_address[:country],
					state: warehouse_address[:state],
					city: warehouse_address[:city],
					zip: warehouse_address[:zip],
				)

				args[:class]	||= 'ActiveShipping::USPS'
				args[:config]	= args[:config].merge( test: true ) unless Rails.env.production?

				@shipping_service = args[:class].constantize.new( args[:config] )

			end

			def process( order, args = {} )
				# @todo
			end

			protected
			def request_shipping_rates( geo_address, line_items )
				packages = []

				line_items.each do |line_item|

					package_shape = line_item.package_shape || 'no_shape'

					unless package_shape == 'no_shape'
						[1..line_item.quantity].each do |i|

							if package_shape == 'cylinder'
								packages << ActiveShipping::Package.new(
									line_item.package_weight,
									[ line_item.package_length, line_item.package_width ],
									cylinder: true	# cylinders have different volume calculations
								)
							else
								packages << ActiveShipping::Package.new(
									line_item.package_weight,
									[ line_item.package_height, line_item.package_width, line_item.package_length ],
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

				rates
			end

		end

	end

end
