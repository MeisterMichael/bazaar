# a list of tax codes
# https://taxcloud.net/tic/

module Bazaar

	class TaxService < ::ApplicationService

		def initialize( args = {} )
		end

		def calculate( obj, args = {} )

			return self.calculate_order( obj ) if obj.is_a? Order
			return self.calculate_cart( obj ) if obj.is_a? Cart

		end

		protected

		def calculate_cart( cart )
			return # @todo deal with tax calculations later.... punted

			country = 'USA'
			state = 'CA'
			city = 'San Diego'
			zip = '92126'

			return unless ['USA', 'US'].include?( country )
			return if order.order_items.blank?

			origin = TaxCloud::Address.new(
				:address1 => Bazaar.origin_address[:street],
				:address2 => Bazaar.origin_address[:street2],
				:city => Bazaar.origin_address[:city],
				:state => Bazaar.origin_address[:state],
				:zip5 => Bazaar.origin_address[:zip]).verify

			destination_info = {
				# :address1 => order.shipping_address.street,
				# :address2 => order.shipping_address.street2,
				:city => city,
				:state => state,
				:zip5 => zip
			}

			puts destination_info

			begin
				destination = TaxCloud::Address.new( destination_info ).verify
			rescue TaxCloud::Errors::ApiError => ex
				cart.errors.add(:base, 'Invalid shipping address.')
				return false
			end


			transaction = TaxCloud::Transaction.new(
				:customer_id => '1',
				:cart_id => '1',
				:origin => origin,
				:destination => destination)

			cart.cart_items.each_with_index do |cart_item, index|
				if cart_item.item.tax_code.present?

					transaction.cart_items << TaxCloud::CartItem.new(
						:index => index,
						:item_id => "#{cart_item.item.class.name.underscore}_#{cart_item.item.id}",
						:tic => cart_item.item.tax_code,
						:price => cart_item.price / 100.0,
						:quantity => cart_item.quantity
					)

				end

			end

			lookup = transaction.lookup # this will return a TaxCloud::Responses::Lookup instance

			cart.update estimated_tax: ( lookup.tax_amount * 100 ).to_i


			return

		end

		def calculate_order( order )
			return # @todo deal with tax calculations later.... punted
			return unless ['USA', 'US'].include?( order.shipping_address.geo_country.abbrev || order.shipping_address.country )
			return if order.order_items.blank?

			origin = TaxCloud::Address.new(
				:address1 => Bazaar.origin_address[:street],
				:address2 => Bazaar.origin_address[:street2],
				:city => Bazaar.origin_address[:city],
				:state => Bazaar.origin_address[:state],
				:zip5 => Bazaar.origin_address[:zip]).verify

			state = order.shipping_address.geo_state.try(:abbrev) || order.shipping_address.state
			destination_info = {
				:address1 => order.shipping_address.street,
				:address2 => order.shipping_address.street2,
				:city => order.shipping_address.city,
				:state => state,
				:zip5 => order.shipping_address.zip
			}

			puts destination_info

			begin
				destination = TaxCloud::Address.new( destination_info ).verify
			rescue TaxCloud::Errors::ApiError => ex
				order.errors.add(:base, 'Invalid shipping address.')
				return false
			end

			transaction = TaxCloud::Transaction.new(
				:customer_id => '1',
				:cart_id => '1',
				:origin => origin,
				:destination => destination)

			order.order_items.each_with_index do |order_item, index|
				if order_item.tax_code.present?

					transaction.cart_items << TaxCloud::CartItem.new(
						:index => index,
						:item_id => "#{order_item.item.class.name.underscore}_#{order_item.item.id}",
						:tic => order_item.tax_code,
						:price => order_item.price / 100.0,
						:quantity => order_item.quantity
					)

				end

			end

			lookup = transaction.lookup # this will return a TaxCloud::Responses::Lookup instance

			if lookup.tax_amount > 0
				order.order_items.new item: nil, subtotal: (lookup.tax_amount * 100).to_i, title: 'Sales Tax', order_item_type: 'tax'
				order.tax = ( lookup.tax_amount * 100 ).to_i
			else
				order.tax = 0
			end


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
			    :amount => order.order_items.select{|order_item| order_item.prod?}.sum(&:amount) / 100,
			    :shipping => order.order_items.select{|order_item| order_item.shipping?}.sum(&:amount) / 100,
			    :nexus_addresses => [{:address_id => 1,
			                          :country => 'US',
			                          :zip => '93101',
			                          :state => 'CA',
			                          :city => 'Santa Barbara',
			                          :street => '1218 State St.'}],
			    :line_items => order.order_items.select{|order_item| order_item.prod?}.collect{|order_item| {
					:quantity => order_item.quantity,
					:unit_price => (order_item.price),
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
