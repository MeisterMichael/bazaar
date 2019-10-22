module Bazaar
	class CartOffersController < ApplicationController
		layout 'bazaar/application'
		# for adding, removing, updating quantity, etc. of items in the cart

		# Disable cross origin security for adding items to cart
		if Bazaar.disable_add_to_cart_authenticity_token_verification
			skip_before_action :verify_authenticity_token, :only => [:create,:destroy]
		end

		def create
			@offer = Bazaar::Offer.active.find( params[:offer_id] ) if params[:offer_id]
			@offer ||= params[:item_type].constantize.find_by( id: params[:item_id] ).offer if params[:item_type]

			if @cart.nil?
				@cart = Cart.create( ip: client_ip )
				session[:cart_id] = @cart.id
			end

			@cart.email = params[:email] if params[:email].present?
			@cart.first_name = params[:first_name] if params[:first_name].present?

			if params[:reset_cart].present?
				@cart.cart_offers.destroy_all
				session[:cart_count] = 0
			end

			params[:quantity] ||= 1

			cart_offer = @cart.cart_offers.where( offer: @offer ).last
			if cart_offer.present?
				cart_offer.increment!( :quantity, params[:quantity].to_i )
			else
				cart_offer = @cart.cart_offers.create( offer: @offer, quantity: params[:quantity].to_i )
			end

			cart_offer_price = @offer.initial_price
			cart_offer.update( price: cart_offer_price, subtotal: cart_offer_price * cart_offer.quantity )

			@cart.update subtotal: @cart.cart_offers.sum( :subtotal )

			session[:cart_count] ||= 0
			session[:cart_count] += params[:quantity].to_i

			log_event( { name:'add_cart', on: @offer, content: "added #{@offer} to their cart." } )

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
			@cart_offer = @cart.cart_offers.find_by( id: params[:id] )
			@cart_offer.destroy
			@cart.update subtotal: @cart.cart_offers.sum(:price)
			session[:cart_count] = @cart.cart_offers.sum(:quantity)

			log_event( { name:'remove_cart', on: @cart_offer.offer, content: "removed #{@cart_offer.offer} from their cart." } )

			redirect_back fallback_location: '/admin'
		end
	end
end
