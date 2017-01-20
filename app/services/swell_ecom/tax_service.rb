module SwellEcom

	class TaxService

		def self.calculate( order )

			order.order_items.new item: nil, amount: 100, label: 'Sales Tax', order_item_type: 'tax'

			return

			origin = TaxCloud::Address.new(
				:address1 => '',
				:address2 => 'Third Floor',
				:city => 'Norwalk',
				:state => 'CT',
				:zip5 => '06851')
			destination = TaxCloud::Address.new(
				:address1 => order.shipping_address.street,
				:address2 => order.shipping_address.street2,
				:city => order.shipping_address.city,
				:state => order.shipping_address.state.code,
				:zip5 => order.shipping_address.zip)


			transaction = TaxCloud::Transaction.new(
				:customer_id => '1',
				:cart_id => '1',
				:origin => origin,
				:destination => destination)

			order.order_items.each_with_index do |order_item, index|


				transaction.cart_items << TaxCloud::CartItem.new(
					:index => index,
					:item_id => order_item.item.code,
					:tic => order_item.item.properties['tax_code'],
					:price => order_item.item.price,
					:quantity => order_item.quantity)

			end

			lookup = transaction.lookup # this will return a TaxCloud::Responses::Lookup instance
			lookup.tax_amount # total tax amount
			# lookup.cart_items.each do |cart_item|
			#	cart_item.tax_amount # tax for a single item
			# end

		end

	end

end
