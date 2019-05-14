module Bazaar
	class CartsController < ApplicationController
		layout 'bazaar/application'
		# really just to show the user's cart

		before_action :get_cart

		def show
			@cart ||= Cart.new( ip: client_ip )

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
						products: @cart.cart_items.collect{|cart_item| cart_item.item.offer.page_event_data.merge( quantity: cart_item.quantity ) }
					}
				}
			)

			log_event( on: @cart )

		end

		def update
			params[:item_quantity].each do |k, v|
				line_item = @cart.cart_items.find( k )
				if v.to_i < 1
					@cart.update subtotal: @cart.subtotal - ( line_item.item.price * line_item.quantity )
					session[:cart_count] = session[:cart_count] - line_item.quantity
					line_item.destroy
				else
					delta = line_item.quantity - v.to_i
					line_item.update( quantity: v, subtotal: line_item.price * v.to_i )
					session[:cart_count] = session[:cart_count] - delta
					@cart.update subtotal: @cart.subtotal - ( line_item.item.price * delta )
				end

			end

			log_event( name: 'update_cart', value: @cart.subtotal, on: @cart, content: "updated cart quantities" )

			redirect_back fallback_location: '/admin'
		end

		private
			def get_cart
				@cart = Cart.find_by( id: session[:cart_id] )
			end

	end
end
