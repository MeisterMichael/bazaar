module SwellEcom

	class TaxService

		def self.calculate( order )

			# order.order_items.new item: nil, amount: 100, label: 'Sales Tax', order_item_type: 'tax'

			# return

			origin = TaxCloud::Address.new(
				:city => 'San Diego',
				:state => 'CA',
				:zip5 => '06851')
			destination = TaxCloud::Address.new(
				:address1 => order.shipping_address.street,
				:address2 => order.shipping_address.street2,
				:city => order.shipping_address.city,
				:state => order.shipping_address.geo_state.try(:code) || order.shipping_address.state || 'CA',
				# :country => order.shipping_address.geo_country.try(:code) || 'USA',
				:zip5 => order.shipping_address.zip)


			transaction = TaxCloud::Transaction.new(
				:customer_id => '1',
				:cart_id => '1',
				:origin => origin,
				:destination => destination)

			order.order_items.select{|order_item| order_item.sku? }.each_with_index do |order_item, index|


				transaction.cart_items << TaxCloud::CartItem.new(
					:index => index,
					:item_id => order_item.item.code,
					:tic => order_item.item.tax_code,
					:price => order_item.item.price,
					:quantity => order_item.quantity )

			end

			lookup = transaction.lookup # this will return a TaxCloud::Responses::Lookup instance
			puts lookup
			puts lookup.tax_amount # total tax amount
			lookup.cart_items.each do |cart_item|
				puts cart_item.tax_amount # tax for a single item
			end

=begin
			client = Taxjar::Client.new(api_key: ENV['TAX_JAR_API_KEY'])

			#order.order_items.new item: nil, amount: 100, label: 'Sales Tax', order_item_type: 'tax'
			client = Taxjar::Client.new(api_key: '48ceecccc8af930bd02597aec0f84a78')

			order_info = {
			    :to_country => order.shipping_address.country.code,
			    :to_zip => order.shipping_address.zip,
			    :to_city => order.shipping_address.city,
			    :to_state => order.shipping_address.state.code,
			    :from_country => 'US',
			    :from_zip => '92014',
			    :from_city => 'San Diego',
			    :amount => order.order_items.select{|order_item| order_item.sku?}.sum(&:amount) / 100,
			    :shipping => order.order_items.select{|order_item| order_item.shipping?}.sum(&:amount) / 100,
			    :nexus_addresses => [{:address_id => 1,
			                          :country => 'US',
			                          :zip => '93101',
			                          :state => 'CA',
			                          :city => 'Santa Barbara',
			                          :street => '1218 State St.'}],
			    :line_items => order.order_items.select{|order_item| order_item.sku?}.collect{|order_item| {
					:quantity => order_item.quantity,
					:unit_price => (order_item.amount / order_item.quantity),
					:product_tax_code => order_item.item.tax_code
				} }
			}

			tax_for_order = client.tax_for_order()
			puts tax_for_order
			return tax_for_order
=end

		end

	end

end
