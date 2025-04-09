# require 'taxjar'

module Bazaar

	module TaxServices

		class TaxJarTaxService

			TAX_RESULTS_FIELDS = %w( state_amount county_amount city_amount special_district_amount state_tax_collectable county_tax_collectable city_tax_collectable special_district_tax_collectable gst pst qst )

			def initialize( args = {} )
				raise Exception.new('add "gem \'taxjar-ruby\'" to your Gemfile and "require \'taxjar\'" at the top of config/initializers/bazaar.rb') unless defined?( Taxjar )

				@environment = args[:environment].to_sym if args[:environment].present?
				@environment ||= :production if Rails.env.production?
				@environment ||= :development

				@client = Taxjar::Client.new(
					api_key: args[:api_key] || ENV['TAX_JAR_API_KEY']
				)

				@warehouse_address = args[:warehouse] || Bazaar.warehouse_address
				@origin_address = args[:origin] || Bazaar.origin_address

				@nexus_addresses = args[:nexus] || []
				unless @nexus_addresses.present?
					Bazaar.nexus_addresses.each do |address|
						@nexus_addresses << {
							:address_id => address[:address_id],
							:country => address[:country],
							:zip => address[:zip],
							:state => address[:state],
							:city => address[:city],
							:street => address[:street]
						}
					end
				end


			end

			def calculate( obj, args = {} )

				return self.calculate_order( obj ) if obj.is_a? Order
				return self.calculate_cart( obj ) if obj.is_a? Cart
				return false

			end

			def process( order, args = {} )
				return true unless @environment == :production
				order_info = get_order_info( order )

				order_info[:sales_tax] = order.tax_as_money
				tax_for_order = @client.tax_for_order( order_info )

				tax_breakdown = tax_for_order.breakdown
				if tax_breakdown.present? && ( line_items = tax_breakdown.line_items.to_a ).present?
					order_info[:line_items].each do |order_info_line_item|
						tax_line_item = line_items.first
						line_items.delete(tax_line_item)

						order_info_line_item[:sales_tax] = tax_line_item.tax_collectable
					end
				end

				begin

					if ( tax_jar_order = @client.show_order( order.code, from_transaction_date: order.created_at.strftime('%Y/%m/%d'), to_transaction_date: order.created_at.strftime('%Y/%m/%d') ) ).present?

						tax_jar_order = @client.update_order( order_info )

					end

				rescue Taxjar::Error::NotFound => e
					e_order_log = OrderLog.new( order: order, subject: e.message, source: 'TaxJarTaxService#calculate_order', details: "#{e.message.to_s}\n#{(e.backtrace || []).join("\n")}" )
					e_order_log.save if order.persisted?
					order.order_logs << e_order_log

					begin

						tax_jar_order = @client.create_order( order_info )

					rescue Exception => e
						e_order_log = OrderLog.new( order: order, subject: e.message, source: 'TaxJarTaxService#calculate_order', details: "#{e.message.to_s}\n#{(e.backtrace || []).join("\n")}" )
						e_order_log.save if order.persisted?
						order.order_logs << e_order_log

						NewRelic::Agent.notice_error(e, custom_params: { 'email' => order.email, 'order_code'	=> order.code } ) if defined?( NewRelic )
						puts e

						return false

					end

				end

				# @todo process refunds
				# order.transactions.negative.each do |refund_transaction|
				# 	refund_info = order_info.merge(
				# 		transaction_id: "refund-#{refund_transaction.id}",
				# 		transaction_date: order.created_at.strftime('%Y/%m/%d'),
				# 		amount: ...
				# 	)
				# end

				tax_jar_order
			end

			def recalculate( obj, args = {} )

				return self.calculate_order( obj ) if obj.is_a? Order
				return self.calculate_cart( obj ) if obj.is_a? Cart
				return false

			end

			protected

			def calculate_cart( cart )
				# don't know shipping address, so can't calculate
			end

			def calculate_order( order )
				order.tax = 0
				return false if order.billing_address.nil?
				return false if not( order.billing_address.validate ) || order.billing_address.geo_country.blank? || order.billing_address.zip.blank?
				return false if order.billing_address.geo_country.abbrev == 'US' && order.billing_address.geo_state.blank?

				order_info = get_order_info( order )

				begin
					tax_for_order = @client.tax_for_order( order_info )
				rescue Taxjar::Error::NotFound => ex
					ex_order_log = OrderLog.new( order: order, subject: ex.message, source: 'TaxJarTaxService#calculate_order', details: "#{ex.message.to_s}\n#{(ex.backtrace || []).join("\n")}" )
					ex_order_log.save if order.persisted?
					order.order_logs << ex_order_log

					NewRelic::Agent.notice_error(ex) if defined?( NewRelic )
					puts ex
					order.billing_address.errors.add :base, :invalid, message: "address is invalid"

				rescue Taxjar::Error::BadRequest => ex

					ex_order_log = OrderLog.new( order: order, subject: ex.message, source: 'TaxJarTaxService#calculate_order', details: "#{ex.message.to_s}\n#{(ex.backtrace || []).join("\n")}" )
					ex_order_log.save if order.persisted?
					order.order_logs << ex_order_log


					if ex.message.include?( 'isn\'t a valid postal code' )
						order.billing_address.errors.add :zip, :invalid, message: "#{order_info[:to_zip]} is not a valid zip/postal code"
						order.errors.add :base, :processing_error, message: "#{order_info[:to_zip]} is not a valid zip/postal code"
						return order
					elsif ex.message.include?( 'is not used within from_state' )
						order.billing_address.errors.add :zip, :invalid, message: "#{order_info[:from_zip]} is not a valid zip/postal code within #{order_info[:from_state]}"
						order.errors.add :base, :processing_error, message: "the billing zip/postal code is not valid"
						return order
					elsif ex.message.include?( 'is not used within to_state' )
						order.shipping_address.errors.add :zip, :invalid, message: "#{order_info[:to_zip]} is not a valid zip/postal code within #{order_info[:to_state]}"
						order.errors.add :base, :processing_error, message: "the shipping zip/postal code is not valid"
						return order
					else
						NewRelic::Agent.notice_error(ex) if defined?( NewRelic )
						puts ex
						order.billing_address.errors.add :base, :invalid, message: "address is invalid"
						return false
					end

				end
				tax_breakdown = tax_for_order.breakdown
				tax_geo = nil

				unless tax_breakdown.present?
					# puts JSON.pretty_generate order_info
					# puts JSON.pretty_generate JSON.parse( tax_for_order.to_json )
					return order
				end


				if tax_for_order.tax_source == 'destination'
					tax_geo = { country: order_info[:from_country], state: order_info[:from_state], city: order_info[:from_city] }
				elsif tax_for_order.tax_source == 'origin'
					tax_geo = { country: order_info[:from_country], state: order_info[:from_state], city: order_info[:from_city] }
				end


				order.tax = (tax_for_order.amount_to_collect * 100).to_i
				order.tax_breakdown = {}

				tax_order_item = order.order_items.new( subtotal: order.tax, title: "Tax", order_item_type: 'tax' )

				TAX_RESULTS_FIELDS.each do |field|
					field_key = field.gsub(/_tax_collectable|_amount$/,'')
					field_value = tax_breakdown.try(field)
					if not( field_value.nil? ) && field_value.abs > 0.0
						field_value = (field_value * 100).to_i # convet to cents
						order.tax_breakdown[field_key] = field_value
						tax_order_item.properties[field] = field_value
					end
				end

				# Save tax breakdown per order offers
				tax_breakdown.line_items.each_with_index do |line_item, index|
					order_offer = order.order_offers.to_a[index]

					if order_offer
						order_offer.tax = (line_item.tax_collectable * 100).to_i
						order_offer.tax_breakdown = {}

						TAX_RESULTS_FIELDS.each do |field|
							field_key = field.gsub(/_tax_collectable|_amount$/,'')
							field_value = line_item.try(field)
							if not( field_value.nil? ) && field_value.abs > 0.0
								field_value = (field_value * 100).to_i # convet to cents
								order_offer.tax_breakdown[field_key] = field_value
							end
						end
					end
				end

				if tax_for_order.freight_taxable
					order.shipments.each do |shipment|
						shipment.tax = (tax_breakdown.shipping.tax_collectable * 100).to_i
						shipment.tax_breakdown = {}

						TAX_RESULTS_FIELDS.each do |field|
							field_key = field.gsub(/_tax_collectable|_amount$/,'')
							field_value = tax_breakdown.shipping.try(field)
							if not( field_value.nil? ) && field_value.abs > 0.0
								field_value = (field_value * 100).to_i # convet to cents
								shipment.tax_breakdown[field_key] = field_value
							end
						end
					end
				else
					order.shipments.to_a.each do |shipment|
						shipment.tax = 0
					end
				end

				return order

			end

			def get_order_info( order )

				shipping_amount = order.shipping_as_money
				discount_total = -order.discount_as_money
				offer_total = order.subtotal_as_money

				discount_remaining = discount_total
				discount_applied = 0

				line_items = []
				order.order_offers.to_a.each do |order_offer|
					discount = [ discount_remaining, -order_offer.subtotal_as_money ].max

					line_items << {
						:quantity => order_offer.quantity,
						:unit_price => order_offer.price_as_money,
						:product_tax_code => order_offer.tax_code,
						:product_identifier => order_offer.offer.code,
						:description => order_offer.title,
						:discount => -discount,
					}

					discount_applied = discount_applied + discount
					discount_remaining = (discount_total - discount_applied).round(8)
				end


				order_info = {
					:to_country => order.shipping_address.geo_country.try(:abbrev),
					:to_zip => order.shipping_address.zip,
					:to_city => order.shipping_address.city,
					:to_state => order.shipping_address.state_abbrev,
					:from_country => @warehouse_address[:country] || @origin_address[:country],
					:from_zip => @warehouse_address[:zip] || @origin_address[:zip],
					:from_city => @warehouse_address[:city] || @origin_address[:city],
					:from_state => @warehouse_address[:state] || @origin_address[:state],
					:amount => (offer_total + shipping_amount + discount_total).round(8),
					:shipping => (shipping_amount + discount_remaining).round(8),
					:nexus_addresses => @nexus_addresses,
					:line_items => line_items,
				}

				order_info[:transaction_id] = order.code if order.code.present?
				order_info[:transaction_date] = order.created_at.strftime('%Y/%m/%d') if order.created_at.present?

				order_info

			end

		end

	end

end
