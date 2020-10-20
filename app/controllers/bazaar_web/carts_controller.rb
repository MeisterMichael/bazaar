module BazaarWeb
	class CartsController < ApplicationController
		layout 'bazaar_web/application'
		# really just to show the user's cart

		before_action :get_cart

		def show
			@cart ||= BazaarCore::Cart.new( ip: client_ip )

			set_page_meta(
				{
					title: 'Shopping Cart - Neurohacker Collective',
					fb_type: 'article'
				}
			)

			add_page_event_data(
				ecommerce: {
					add: {
						actionField: {},
						products: @cart.cart_offers.collect{|cart_offer| cart_offer.offer.page_event_data.merge( quantity: cart_offer.quantity ) }
					}
				}
			)

			log_event( on: @cart )

		end

		def update
			params[:item_quantity].each do |k, v|
				cart_offer = @cart.cart_offers.find( k )
				if v.to_i < 1
					@cart.update subtotal: @cart.subtotal - ( cart_offer.price * cart_offer.quantity )
					session[:cart_count] = session[:cart_count] - cart_offer.quantity
					cart_offer.destroy
				else
					delta = cart_offer.quantity - v.to_i
					cart_offer.update( quantity: v, subtotal: cart_offer.price * v.to_i )
					session[:cart_count] = session[:cart_count] - delta
					@cart.update subtotal: @cart.subtotal - ( cart_offer.price * delta )
				end

			end

			log_event( name: 'update_cart', value: @cart.subtotal, on: @cart, content: "updated cart quantities" )

			if params[:checkout]
				redirect_to bazaar.checkout_index_path( buy_now: 1 )
			else
				redirect_back fallback_location: '/cart'
			end


		end

		private
			def get_cart
				@cart = BazaarCore::Cart.find_by( id: session[:cart_id] )
			end

	end
end
