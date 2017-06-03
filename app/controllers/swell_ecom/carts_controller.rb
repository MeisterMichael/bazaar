module SwellEcom
	class CartsController < ApplicationController
		# really just to show the user's cart

		before_filter :get_cart

		def show
			
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
			redirect_to :back
		end

		private
			def get_cart
				@cart = Cart.find_by( id: session[:cart_id] )
			end

	end
end