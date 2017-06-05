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

			line_item = @cart.cart_items.where( item_type: @item.class.name, item_id: @item.id ).last
			if line_item.present?
				line_item.increment!( :quantity, params[:quantity].to_i )
			else
				line_item = @cart.cart_items.create( item_type: @item.class.name, item_id: @item.id, quantity: params[:quantity] )
			end

			line_item.update( price: line_item.item.price, subtotal: line_item.item.price * line_item.quantity )

			@cart.update subtotal: @cart.subtotal + ( line_item.item.price * line_item.quantity )

			session[:cart_count] ||= 0
			session[:cart_count] += params[:quantity].to_i

			count = ""
			if params[:quantity].to_i > 1
				count = "#{params[:quantity]}X "
			end
			set_flash "<div class='row'><div class='col-xs-3 col-sm-2 col-lg-1'><img src='#{@item.avatar}' class='img img-responsive' /></div> <div class='col-xs-9 col-sm-10 col-lg-11'>#{count}#{@item.title} Added to your <a href='/cart'>cart</a>. <br> <a href='/checkout'>Checkout</a>, or <a href='#' data-dismiss='alert'> Keep Shopping</a>.</div></div>"

			redirect_to :back
		end

		def destroy
			@line_item = @cart.cart_items.find_by( id: params[:id] )
			@line_item.destroy
			@cart.update subtotal: @cart.subtotal - ( @line_item.item.price * @line_item.quantity )
			session[:cart_count] -= @line_item.quantity
			redirect_to :back
		end
	end
end