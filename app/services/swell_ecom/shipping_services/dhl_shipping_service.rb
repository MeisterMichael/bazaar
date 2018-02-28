

# require 'dhl-get_quote'

require 'rest-client'

# Gem requirements
# => gem 'dhl-get_quote'

module SwellEcom

	module ShippingServices

		class DHLShippingService < SwellEcom::ShippingService

			# https://api.dhlglobalmail.com/docs/v1/track.html
			JSON_TRACKING_ENDPOINT = 'https://api.dhlglobalmail.com/v1/mailitems/track'

			def initialize( args = {} )
				super( args )

			end
		end
	end
end




# 			def initialize( args = {} )
# 				super( args )

# 				warehouse_address = args[:warehouse] || SwellEcom.warehouse_address

# 				@site_id = args[:site_id]
# 				@password = args[:password]
# 				@text_mode = true unless Rails.env.production?  # changes the url being hit
# 				@special_services = args[:special_services] || []

# 			end

# 			def process( order, args = {} )
# 				# @todo
# 			end

# 			protected
# 			def request_address_rates( geo_address, line_items, args = {} )

# 				r = Dhl::GetQuote::Request.new(
# 					:site_id => @site_id,
# 					:password => @password,
# 					:test_mode => @text_mode
# 				)

# 				r.metric_measurements!

# 				@special_services.each do |special_service|
# 					r.add_special_service( special_service )
# 				end

# 				r.to( geo_address.geo_country.abbrev, geo_address.zip )
# 				r.from( @warehouse_address[:country], @warehouse_address[:zip] )


# 				line_items.each do |line_item|

# 					package_shape = line_item.package_shape || 'no_shape'

# 					unless package_shape == 'no_shape'

# 						package_weight = line_item.package_weight / 1000.0 # g to kg
# =======
# 				@access_token	= args[:access_token]
# 				@username		= args[:username]
# 				@password		= args[:password]
# 				@client_id		= args[:client_id]

# 			end

# 			def fetch_delivery_status_for_code( code, args = {} )

# 				options = { number: code, access_token: @access_token, client_id: @client_id }

# 				raw_result = RestClient.get JSON_TRACKING_ENDPOINT, {content_type: :json, accept: :json, params: options }
# 				result = JSON.parse( raw_result, symbolize_names: true )
# 				mail_item = result[:data][:mailItems].first

# 				status = {
# 					status: nil,
# 					tracking_number: code,
# 					events: [],
# 					scheduled_delivered_at: nil,
# 					delivered_at: nil,
# 					shipped_at: nil,
# 					carrier_name: 'DHL Ecommerce',
# 				}

# 				mail_item[:events].each do |event|
# 					time = Time.parse("#{event[:date]} #{event[:time]} #{event[:timeZone]}")

# 					status[:events] << { name: event[:description], location: event[:location], country: event[:country], time: time, message: event[:secondaryEventDesc] }
# 					puts "#{event.name} at #{event.location.city}, #{event.location.state} on #{event.time}. #{event.message}"
# 					status[:delivered_at] = time if event[:description].downcase.include?( 'delivered' )
# 					status[:shipped_at] = [ (status[:shipped_at] || time), time ].min

# 				end

# 				status[:status] = :delivered if status[:delivered_at]

# 				status
# 			end
# >>>>>>> dbbdd9be4fc0e9801358e9bc9d95c963b3bab88c

# 						[1..line_item.quantity].each do |i|
# 							if line_item.package_length && line_item.package_width && line_item.package_height
# 								r.pieces << Dhl::GetQuote::Piece.new(
# 									:height	=> line_item.package_height,
# 									:weight	=> package_weight,
# 									:width	=> line_item.package_width,
# 									:depth	=> line_item.package_length
# 								)
# 							else
# 								r.pieces << Dhl::GetQuote::Piece.new(
# 									:weight	=> package_weight,
# 								)
# 							end

# 						end
# 					end
# 				end

# 				response = r.post

# 				if response.error?
# 					raise "There was an error: #{response.raw_xml}"
# 				else
# 					# puts "Your cost to ship will be: #{response.total_amount} in #{response.currency_code}."
# 					rates = []
# 					rates << { name: 'DHL', code: 'DHL', price: (response.total_amount.to_f * 100).to_i, carrier: 'DHL', currency: response.currency_code }
# 				end

# 				rates
# 			end

# 		end

# 	end

# end

# <<<<<<< HEAD
# =======
# end
# >>>>>>> dbbdd9be4fc0e9801358e9bc9d95c963b3bab88c
