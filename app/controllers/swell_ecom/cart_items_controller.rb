module SwellEcom
	class CartItemsController < ApplicationController
		# for adding, removing, updating quantity, etc. of items in the cart

		def create
			@item = params[:item_type].constantize.find_by( id: params[:item_id] )

			if params[:variant_id].present?
				@item = @item.product_variants.find_by( id: params[:variant_id] )
			end

			if @cart.nil?
				@cart = Cart.create( ip: request.ip )
				session[:cart_id] = @cart.id
			end

			line_item = @cart.cart_items.create( item_type: @item.class.name, item_id: @item.id, quantity: params[:quantity] )
			line_item.update( price: line_item.item.price, subtotal: line_item.item.price * line_item.quantity )

			session[:cart_count] ||= 0
			session[:cart_count] += params[:quantity].to_i

			redirect_to :back
		end

		def destroy
			@line_item = @cart.cart_items.find_by( id: params[:id] )
			@line_item.destroy
			session[:cart_count] -= @line_item.quantity
			redirect_to :back
		end
	end
end