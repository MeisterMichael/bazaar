module SwellEcom

	class TaxService

		# a list of tax codes
		# https://taxcloud.net/tic/

		def self.calculate( order )

			origin = TaxCloud::Address.new(
				:address1 => SwellEcom.origin_address[:street],
				:address2 => SwellEcom.origin_address[:street2],
				:city => SwellEcom.origin_address[:city],
				:state => SwellEcom.origin_address[:state],
				:zip5 => SwellEcom.origin_address[:zip]).verify

			destination = TaxCloud::Address.new(
				:address1 => order.shipping_address.street,
				:address2 => order.shipping_address.street2,
				:city => order.shipping_address.city,
				:state => order.shipping_address.geo_state.try(:code) || order.shipping_address.state,
				:zip5 => order.shipping_address.zip
			).verify


			transaction = TaxCloud::Transaction.new(
				:customer_id => '1',
				:cart_id => '1',
				:origin => origin,
				:destination => destination)

			order.order_items.each_with_index do |order_item, index|
				if order_item.get_tax_code.present?

					transaction.cart_items << TaxCloud::CartItem.new(
						:index => index,
						:item_id => order_item.item.code,
						:tic => order_item.get_tax_code,
						:price => (order_item.amount / order_item.quantity) / 100.0,
						:quantity => order_item.quantity
					)

				end

			end

			lookup = transaction.lookup # this will return a TaxCloud::Responses::Lookup instance

			order.order_items.new item: nil, amount: (lookup.tax_amount * 100).to_i, label: 'Sales Tax', order_item_type: 'tax'



			return
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

=begin
			line = Avalara::Request::Line.new({
			  line_no: "1",
			  destination_code: "1",
			  origin_code: "1",
			  qty: "1",
			  amount: 10
			})

			address = Avalara::Request::Address.new({
			  address_code: 1,
			  line_1: "435 Ericksen Avenue Northeast",
			  line_2: "#250",
			  postal_code: "98110"
			})

			invoice = Avalara::Request::Invoice.new({
			  doc_date: Time.now,
			  company_code: 1,
			  lines: [line],
			  addresses: [address]
			})

			# You'll get back a Response::Invoice object
			result = Avalara.get_tax(invoice)

			puts result.result_code
			puts result.total_amount
			puts result.total_tax
			puts result.total_tax_calculated
=end

		end

	end

end
