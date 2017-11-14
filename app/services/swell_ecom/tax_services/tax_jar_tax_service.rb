require 'taxjar'

module SwellEcom

	module TaxServices

		class TaxJarTaxService

			def initialize( args = {} )

				@client = Taxjar::Client.new(
					api_key: args[:api_key] || ENV['TAX_JAR_API_KEY']
				)

				@warehouse_address = args[:warehouse] || SwellEcom.warehouse_address
				@origin_address = args[:origin] || SwellEcom.origin_address

			end

			def calculate( obj, args = {} )

				return self.calculate_order( obj ) if obj.is_a? Order
				return self.calculate_cart( obj ) if obj.is_a? Cart

			end

			protected

			def calculate_cart( cart )
				# don't know shipping address, so can't calculate
			end

			def calculate_order( order )
				return # @todo
				shipping_amount = order.order_items.shipping.sum(:subtotal) / 100.0
				order_total = order.total / 100.0

				order_info = {
				    :to_country => order.shipping_address.country.code,
				    :to_zip => order.shipping_address.zip,
				    :to_city => order.shipping_address.city,
				    :to_state => order.shipping_address.state.code,
				    :from_country => @warehouse_address[:country] || @origin_address[:country] || 'US',
				    :from_zip => @warehouse_address[:zip] || @origin_address[:zip],
				    :from_city => @warehouse_address[:city] || @origin_address[:city],
				    :from_state => @warehouse_address[:state] || @origin_address[:state],
				    :amount => order_total - shipping_amount,
				    :shipping => shipping_amount,
				    :nexus_addresses => [{:address_id => @origin_address[:address_id],
				                          :country => @origin_address[:country] || 'US',
				                          :zip => @origin_address[:zip],
				                          :state => @origin_address[:state],
				                          :city => @origin_address[:city],
				                          :street => @origin_address[:street] }],
				    :line_items => order.order_items.select{|order_item| order_item.prod?}.collect{|order_item| {
						:quantity => order_item.quantity,
						:unit_price => (order_item.price / 100.0),
						:product_tax_code => order_item.item.tax_code
					} }
				}

				tax_for_order = client.tax_for_order( order_info )
				tax_breakdown = tax_for_order.breakdown
				tax_geo = nil

				puts tax_for_order

				if tax_for_order.tax_source == 'destination'
					tax_geo = { country: order_info[:from_country], state: order_info[:from_state], city: order_info[:from_city] }
				elsif tax_for_order.tax_source == 'origin'
					tax_geo = { country: order_info[:from_country], state: order_info[:from_state], city: order_info[:from_city] }
				end

				tax_order_items = []
				tax_order_items << order.order_items.new( amount: (tax_breakdown.country_tax_collectable * 100).to_i, label: "Taxes (#{tax_geo[:country]})", order_item_type: 'taxes' ) if tax_breakdown.country_tax_collectable != 0.0
				tax_order_items << order.order_items.new( amount: (tax_breakdown.state_tax_collectable * 100).to_i, label: "Taxes (#{tax_geo[:state]})", order_item_type: 'taxes' ) if tax_breakdown.state_tax_collectable != 0.0
				tax_order_items << order.order_items.new( amount: (tax_breakdown.city_tax_collectable * 100).to_i, label: "Taxes (#{tax_geo[:city]})", order_item_type: 'taxes' ) if tax_breakdown.city_tax_collectable != 0.0

				puts tax_order_items
				die()

				return tax_for_order

			end

		end

	end

end
