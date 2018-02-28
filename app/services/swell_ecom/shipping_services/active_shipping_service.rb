
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
				# args[:config]	= args[:config].merge( test: true ) unless Rails.env.production?

				@shipping_service = args[:class].constantize.new( args[:config] )

			end

			def fetch_delivery_status_for_code( code, args = {} )
				tracking_info = @shipping_service.find_tracking_info( code, args )
				status = {
					status: tracking_info.status,
					tracking_number: tracking_info.tracking_number,
					events: [],
					scheduled_delivered_at: tracking_info.scheduled_delivery_date,
					delivered_at: tracking_info.actual_delivery_date,
					shipped_at: tracking_info.ship_time,
					carrier_name: tracking_info.carrier_name,
				}

				tracking_info.shipment_events.each do |event|
					status[:events] << { name: event.name, city: event.location.city, state: event.location.state, country: event.location.country.name, time: event.time, message: event.message }

					status[:delivered_at] = event.time if event.name.downcase.include?( 'delivered' )
					status[:shipped_at] ||= event.time
				end

				status
			end

			def process( order, args = {} )
				# @todo
			end

			protected
			def request_address_rates( geo_address, line_items, args = {} )
				packages = []

				line_items.each do |line_item|

					package_shape = line_item.package_shape || 'no_shape'

					unless package_shape == 'no_shape'

						options = { units: :metic }

						dims = []
						dims = [ line_item.package_height, line_item.package_width, line_item.package_length ] if line_item.package_length && line_item.package_width && line_item.package_height

						if package_shape == 'cylinder'
							options = options.merge( cylinder: true )
							dims = [ line_item.package_length, line_item.package_width ] if line_item.package_length && line_item.package_width
						end

						[1..line_item.quantity].each do |i|

							packages << ActiveShipping::Package.new(
								line_item.package_weight,
								dims,
								options
							)

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
					{ name: rate.service_name, code: rate.service_code, price: rate.total_price.to_i, carrier: rate.carrier, currency: rate.currency }
				end

				rates
			end

		end

	end

end
