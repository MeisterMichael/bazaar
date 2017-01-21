
module SwellEcom
	class CheckoutController < ApplicationController

		def new
			order_items_attributes		= params[:items]

			@order = Order.new currency: 'usd'

			order_items_attributes.each do |order_item|
				puts order_item

				item = Sku.find_by( code: order_item[:code] )
				puts item
				@order.order_items.new item: item, amount: item.price, label: item.name, order_item_type: 'sku', quantity: order_item[:qty] || 1
				# @todo add plans
			end

		end

		def create
			order_attributes 			= params.require(:order).permit(:email, :customer_comment)
			order_items_attributes		= params[:order][:order_items]
			shipping_address_attributes = params.require(:order).require(:shipping_address).permit(:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name)
			billing_address_attributes	= params.require(:order).require(:billing_address).permit(:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name)

			@order = Order.new order_attributes.merge( currency: 'usd' )
			@order.shipping_address = GeoAddress.new shipping_address_attributes
			@order.billing_address 	= GeoAddress.new billing_address_attributes

			order_items_attributes.each do |order_item|
				item = Sku.find_by( code: order_item[:code] )

				@order.order_items.new item: item, amount: item.price, label: item.name, order_item_type: 'sku', quantity: order_item[:quantity]
				# @todo add plans
			end

			TaxService.calculate( @order )
			ShippingService.calculate( @order )

			StripeService.process( @order, params[:stripeToken] )

			if @order.errors.present?

				set_flash @order.errors.full_messages, :danger
				redirect_to :back

			else

				redirect_to swell_ecom.order_path( @order.code )

			end


		end



	end
end
