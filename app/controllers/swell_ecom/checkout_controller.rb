
module SwellEcom
	class CheckoutController < ApplicationController

		before_filter :get_order, only: [ :confirm, :create, :index ]
		before_filter :initialize_services, only: [ :confirm, :create ]

		def confirm

			@shipping_service.calculate( @order, order_options )
			@tax_service.calculate( @order )
			@transaction_service.calculate( @order, order_options )

		end

		def create

			@shipping_service.calculate( @order, order_options )
			@tax_service.calculate( @order )
			@transaction_service.process( @order, order_options )

			if params[:newsletter].present?
				SwellMedia::Optin.create( email: @order.email, name: "#{@order.billing_address.first_name} #{@order.billing_address.last_name}" )
			end


			if @order.errors.present?
				set_flash @order.errors.full_messages, :danger
				redirect_to :back
			else
				session[:cart_count] = 0
				session[:cart_id] = nil

				@cart.update( order_id: @order.id, status: 'success' )

				OrderMailer.receipt( @order ).deliver_now
				#OrderMailer.notify_admin( @order ).deliver_now

				redirect_to swell_ecom.thank_you_order_path( @order.code )

			end


		end

		def index

			@billing_countries 	= SwellEcom::GeoCountry.all
			@shipping_countries = SwellEcom::GeoCountry.all

			@billing_countries = @billing_countries.where( abbrev: SwellEcom.billing_countries[:only] ) if SwellEcom.billing_countries[:only].present?
			@billing_countries = @billing_countries.where( abbrev: SwellEcom.billing_countries[:except] ) if SwellEcom.billing_countries[:except].present?

			@shipping_countries = @shipping_countries.where( abbrev: SwellEcom.shipping_countries[:only] ) if SwellEcom.shipping_countries[:only].present?
			@shipping_countries = @shipping_countries.where( abbrev: SwellEcom.shipping_countries[:except] ) if SwellEcom.shipping_countries[:except].present?

			@billing_states 	= SwellEcom::GeoState.where( geo_country_id: @order.shipping_address.try(:geo_country_id) || @billing_countries.first.id ) if @billing_countries.count == 1
			@shipping_states	= SwellEcom::GeoState.where( geo_country_id: @order.billing_address.try(:geo_country_id) || @shipping_countries.first.id ) if @shipping_countries.count == 1

			@cart.init_checkout!

			add_page_event_data(
				ecommerce: {
					checkout: {
						actionField: {},
						products: @cart.cart_items.collect{|cart_item| cart_item.item.page_event_data.merge( quantity: cart_item.quantity ) }
					}
				}
			);

		end

		def new
			redirect_to checkout_index_path( params.merge( controller: nil, action: nil ) )
		end

		def state_input

			@order = Order.new currency: 'usd'
			@order.shipping_address = GeoAddress.new
			@order.billing_address 	= GeoAddress.new

			@address_attribute = ( params[:address_attribute] == 'billing_address' ? :billing_address : :shipping_address )
			@states = SwellEcom::GeoState.where( geo_country_id: params[:geo_country_id] )

			render layout: false

		end


		private

		def get_order

			if @cart.nil?
				redirect_to '/cart'
				return false
			end

			if params[:order].present?

				order_attributes 			= params.require(:order).permit(:email, :customer_notes)
				order_items_attributes		= params[:order][:order_items]
				billing_address_attributes	= params.require(:order).require(:billing_address ).permit( :phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name )

				if params[:same_as_billing]

					shipping_address_attributes = params.require(:order).require(:billing_address).permit( :phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name )

				else

					shipping_address_attributes = params.require(:order).require(:shipping_address).permit( :phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name )

				end

			else
				order_attributes = {}
				order_items_attributes		= params[:items]
				shipping_address_attributes = {}
				billing_address_attributes = {}
			end

			@order = Order.new order_attributes.merge( currency: 'usd' )
			@order.shipping_address = GeoAddress.new shipping_address_attributes.merge( user: current_user )
			@order.billing_address 	= GeoAddress.new billing_address_attributes.merge( user: current_user )

			@order.subtotal = @cart.subtotal
			@cart.cart_items.each do |cart_item|
				@order.order_items.new item: cart_item.item, price: cart_item.price, subtotal: cart_item.subtotal, order_item_type: 'prod', quantity: cart_item.quantity, title: cart_item.item.title, tax_code: cart_item.item.tax_code
			end

		end

		def initialize_services

			@shipping_service = SwellEcom.shipping_service_class.constantize.new( SwellEcom.shipping_service_config )
			@tax_service = SwellEcom.tax_service_class.constantize.new( SwellEcom.tax_service_config )
			@transaction_service = SwellEcom.transaction_service_class.constantize.new( SwellEcom.transaction_service_config )

		end

		def order_options
			params.slice( :stripeToken )
		end



	end
end
