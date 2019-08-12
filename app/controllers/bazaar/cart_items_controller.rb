module Bazaar
	class CartItemsController < ApplicationController
		layout 'bazaar/application'
		# for adding, removing, updating quantity, etc. of items in the cart

		# Disable cross origin security for adding items to cart
		if Bazaar.disable_add_to_cart_authenticity_token_verification
			skip_before_action :verify_authenticity_token, :only => [:create,:destroy]
		end

		def create
			@item = params[:item_type].constantize.find_by( id: params[:item_id] )

			if params[:variant_id].present?
				@item = @item.product_variants.find_by( id: params[:variant_id] )
			end

			if @cart.nil?
				@cart = Cart.create( ip: client_ip )
				session[:cart_id] = @cart.id
			end

			@cart.email = params[:email] if params[:email].present?
			@cart.first_name = params[:first_name] if params[:first_name].present?

			if params[:reset_cart].present?
				@cart.cart_items.destroy_all
				session[:cart_count] = 0
			end

			params[:quantity] ||= 1

			line_item = @cart.cart_items.where( item_type: @item.class.name, item_id: @item.id ).last
			if line_item.present?
				line_item.increment!( :quantity, params[:quantity].to_i )
			else
				line_item = @cart.cart_items.create( item_type: @item.class.name, item_id: @item.id, quantity: params[:quantity] )
			end

			line_item_price = line_item.item.price
			line_item_price = line_item.item.trial_price if line_item.item.is_a?( SubscriptionPlan ) && line_item.item.trial?

			line_item.update( price: line_item_price, subtotal: line_item_price * line_item.quantity )

			@cart.update subtotal: @cart.cart_items.sum( :subtotal )

			session[:cart_count] ||= 0
			session[:cart_count] += params[:quantity].to_i

			count = ""
			if params[:quantity].to_i > 1
				count = "#{params[:quantity]}X "
			end



			log_event( { name:'add_cart', on: @item, content: "added #{@item} to their cart." } )


			#set_flash "<div class='row'><div class='col-xs-3 col-sm-2 col-lg-1'><img src='#{@item.avatar}' class='img img-responsive' /></div> <div class='col-xs-9 col-sm-10 col-lg-11'>#{count}#{@item.title} Added to your <a href='/cart'>Cart</a>. <br> <a href='/checkout'>Checkout</a>, or <a href='#' data-dismiss='alert'> Keep Shopping</a>.</div></div>"


			respond_to do |format|
				format.json {
				}
				format.html {
					if params[:buy_now]
						redirect_to bazaar.checkout_index_path( buy_now: 1 )
					else
						redirect_to '/cart'
					end
				}
			end
		end

		def destroy
			@line_item = @cart.cart_items.find_by( id: params[:id] )
			@line_item.destroy
			@cart.update subtotal: @cart.subtotal - ( @line_item.item.price * @line_item.quantity )
			session[:cart_count] -= @line_item.quantity

			log_event( { name:'remove_cart', on: @item, content: "removed #{@item} from their cart." } )

			redirect_back fallback_location: '/admin'
		end
	end
end
