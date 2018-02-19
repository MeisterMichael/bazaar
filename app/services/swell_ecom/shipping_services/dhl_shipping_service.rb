
require 'dhl-get_quote'
# Gem requirements
# => gem 'dhl-get_quote'

module SwellEcom

	module ShippingServices

		class DHLShippingService < SwellEcom::ShippingService

			def initialize( args = {} )
				super( args )

				warehouse_address = args[:warehouse] || SwellEcom.warehouse_address

				@site_id = args[:site_id]
				@password = args[:password]
				@text_mode = true unless Rails.env.production?  # changes the url being hit
				@special_services = args[:special_services] || []

			end

			def process( order, args = {} )
				# @todo
			end

			protected
			def request_shipping_rates( geo_address, line_items )

				r = Dhl::GetQuote::Request.new(
					:site_id => @site_id,
					:password => @password,
					:test_mode => @text_mode
				)

				r.metric_measurements!

				@special_services.each do |special_service|
					r.add_special_service( special_service )
				end

				r.to( geo_address.geo_country.abbrev, geo_address.zip )
				r.from( @warehouse_address[:country], @warehouse_address[:zip] )


				line_items.each do |line_item|

					package_shape = line_item.package_shape || 'no_shape'

					unless package_shape == 'no_shape'

						package_weight = line_item.package_weight / 1000.0 # g to kg

						[1..line_item.quantity].each do |i|

							r.pieces << Dhl::GetQuote::Piece.new(
								:height	=> line_item.package_height,
								:weight	=> package_weight,
								:width	=> line_item.package_width,
								:depth	=> line_item.package_length
							)

						end
					end
				end

				response = r.post
				
				if response.error?
					raise "There was an error: #{response.raw_xml}"
				else
					# puts "Your cost to ship will be: #{response.total_amount} in #{response.currency_code}."
					rates = []
					rates << { name: 'DHL', code: 'DHL', price: (response.total_amount.to_f * 100).to_i, carrier: 'DHL', currency: response.currency_code }
				end

				rates
			end

		end

	end

end
