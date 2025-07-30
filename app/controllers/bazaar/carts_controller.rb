module Bazaar
	class CartsController < ApplicationController
		layout 'bazaar/application'
		# really just to show the user's cart

		before_action :get_or_create_bazaar_cart

		def show

			set_page_meta(
				{
					title: 'Shopping Cart - Neurohacker Collective',
					fb_type: 'article'
				}
			)

			if @cart.cart_offers.present?
				add_page_event_data(
					ecommerce: {
						add: {
							actionField: {},
							products: @cart.cart_offers.collect{|cart_offer| cart_offer.offer.page_event_data.merge( quantity: cart_offer.quantity ) }
						}
					}
				)
			end

			log_event( on: @cart )

			render 'show'
		end

		def update
			return show() if params[:item_quantity].blank?

			params[:item_quantity].each do |k, v|

				cart_offer = @cart.cart_offers.find( k )

				quantity = v.to_i
				quantity = [ quantity, cart_offer.offer.per_cart_limit ].min if cart_offer.offer.try(:per_cart_limit).present?

				if quantity < 1
					@cart.update subtotal: @cart.subtotal - ( cart_offer.price * cart_offer.quantity )
					session[:cart_count] = session[:cart_count] - cart_offer.quantity
					cart_offer.destroy
				else
					delta = cart_offer.quantity - quantity
					cart_offer.update( quantity: quantity, subtotal: cart_offer.price * quantity )
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

	end
end
