
module SwellEcom
	class CheckoutController < ApplicationController

		before_filter :get_order, only: [ :confirm, :create, :new ]

		def new

			@billing_countries = @shipping_countries = SwellEcom::GeoCountry.all

			@shipping_states = SwellEcom::GeoState.where( geo_country_id: @order.shipping_address.try(:geo_country_id) || @billing_countries.first.id )
			@billing_states = SwellEcom::GeoState.where( geo_country_id: @order.billing_address.try(:geo_country_id) || @shipping_countries.first.id )

		end

		def confirm

			ShippingService.calculate( @order )
			TaxService.calculate( @order )
			TransactionService.calculate( @order )

		end

		def create


			ShippingService.calculate( @order )
			TaxService.calculate( @order )
			TransactionService.process( @order, stripe_token: params[:stripeToken] )

			if @order.errors.present?

				set_flash @order.errors.full_messages, :danger
				redirect_to :back

			else

				# @todo email receipt
				redirect_to swell_ecom.order_path( @order.code )

			end


		end


		private

		def get_order


			if params[:order].present?
				order_attributes 			= params.require(:order).permit(:email, :customer_comment)
				order_items_attributes		= params[:order][:order_items]
				shipping_address_attributes = params.require(:order).require(:shipping_address).permit( :phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name )
				billing_address_attributes	= params.require(:order).require(:billing_address ).permit( :phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name )
			else
				order_attributes = {}
				order_items_attributes		= params[:items]
				shipping_address_attributes = {}
				billing_address_attributes = {}
			end

			@order = Order.new order_attributes.merge( currency: 'usd' )
			@order.shipping_address = GeoAddress.new shipping_address_attributes
			@order.billing_address 	= GeoAddress.new billing_address_attributes

			order_items_attributes.each do |order_item|
				item = Sku.find_by( code: order_item[:code] )

				@order.order_items.new item: item, amount: item.price, label: item.name, order_item_type: 'sku', quantity: (order_item[:quantity] || 1)
				# @todo add plans
			end

		end



	end
end
