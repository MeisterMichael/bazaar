module SwellEcom
	class CartItemsController < ApplicationController
		# for adding, removing, updating quantity, etc. of items in the cart

		def create
			@cart = Cart.find_by( id: cookies[:cart] )

			if @cart.nil?
				@cart = Cart.create( ip: request.ip )
				cookies[:cart] = { id: @cart.id, quantity: params[:quantity] }
			end

			@cart.cart_items.create( item_type: 'Product', item_id: params[:product_id], quantity: params[:quantity] )
		end
	end
end