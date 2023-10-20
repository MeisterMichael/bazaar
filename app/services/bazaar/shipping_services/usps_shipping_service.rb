require 'uri'

module Bazaar

	module ShippingServices

		class UspsShippingService < Bazaar::ShippingService

			def initialize( args = {} )

				super( args )

				@login		= args[:login] || ENV["USPS_API_LOGIN"]
				@password	= args[:password] || ENV["USPS_API_PASSWORD"]

			end

			def fetch_delivery_status_for_code( code, args = {} )

				begin

					options = { login: @login }
					tracking_infos = [{ number: code }]


					xml_builder = Nokogiri::XML::Builder.new do |xml|
						xml.TrackFieldRequest('USERID' => options[:login]) do
							xml.Revision { xml.text('1') }
							xml.ClientIp { xml.text(options[:client_ip] || '127.0.0.1') }
							xml.SourceId { xml.text(options[:source_id] || 'active_shipping') }
							tracking_infos.each do |info|
								xml.TrackID('ID' => info[:number]) do
									xml.DestinationZipCode { xml.text(strip_zip(info[:destination_zip]))} if info[:destination_zip]
									if info[:mailing_date]
										formatted_date = info[:mailing_date].strftime('%Y-%m-%d')
										xml.MailingDate { xml.text(formatted_date)}
									end
								end
							end
						end
					end
					request = xml_builder.to_xml.strip.gsub(/\s*\n\s*/,'')

					url = "http://production.shippingapis.com/ShippingAPI.dll?API=TrackV2&XML=#{URI.encode_uri_component(request)}"
					# url = "https://production.shippingapis.com/ShippingAPI.dll?API=TrackV2&XML=#{action_xml}"

					res = RestClient.get(url)
					res_xml = Nokogiri::XML.parse(res.body)


					# Check for Errors
					tracking_error = Nokogiri::XML.parse(res.body).css('Error').first
					if tracking_error.present?
						error_message = tracking_error.css('Description').children.first.try(:text)
						raise Exception.new(error_message) if error_message.present?
						raise Exception.new(tracking_error.to_s)
					end

					# Get tracking info
					tracking_info = Nokogiri::XML.parse(res.body).css('TrackInfo').first

					tracking_number = tracking_info.attributes['ID'].value
					tracking_status = tracking_info.css('Status').children.first.text

					status = {
						status: tracking_status,
						tracking_number: tracking_number,
						events: [],
						scheduled_delivered_at: nil,
						delivered_at: nil,
						shipped_at: nil,
						carrier_name: 'USPS',
					}

					tracking_info.css('TrackDetail').each do |track_detail|
						event_name = track_detail.css('Event').children.first.text
						event_time = Time.parse("#{track_detail.css('EventDate').children.first.text} #{track_detail.css('EventTime').children.first.text}")
						status[:events] << {
							name: event_name,
							city: track_detail.css('EventCity').children.first.try(:text),
							state: track_detail.css('EventState').children.first.try(:text),
							country: track_detail.css('EventCountry').children.first.try(:text),
							time: event_time,
							message: event_name,
						}

						status[:delivered_at] = event_time if event_name.downcase.include?( 'delivered' )
						status[:shipped_at] ||= event_time
					end


					# Update shipment, if present
					if args[:shipment].present?
						shipment = args[:shipment]

						shipment.carrier		= status[:carrier_name]

						shipment.shipped_at		= status[:shipped_at]
						shipment.delivered_at	= status[:delivered_at]

						shipment.status = 'shipped' if shipment.shipped_at
						shipment.status = 'delivered' if shipment.delivered_at

						tracking_info.shipment_events.each do |event|
							created_at = Time.parse(event.time.to_s)

							shipment.shipment_logs.create_with(
								subject: event.name,
								details: event.message,
							).find_or_create_by( created_at: created_at, carrier_status: event.name )
						end

						shipment.save

					end
				rescue Exception => e
					return false if e.message.include? 'status update is not yet available'
					NewRelic::Agent.notice_error(e) if defined?( NewRelic )
					return false
				end

				status
			end

			def process( order, args = {} )
				return false
			end

			protected
			def request_address_rates( geo_address, line_items, args = {} )
				return false
			end

		end

	end

end
