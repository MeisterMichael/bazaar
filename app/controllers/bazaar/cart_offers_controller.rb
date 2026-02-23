module Bazaar
	class CartOffersController < ApplicationController
		layout 'bazaar/application'
		# for adding, removing, updating quantity, etc. of items in the cart

		# Disable cross origin security for adding items to cart
		if Bazaar.disable_add_to_cart_authenticity_token_verification
			skip_before_action :verify_authenticity_token, :only => [:create,:destroy]
		end

		def create
			@offer = Bazaar::Offer.active.joins(:product).where( bazaar_products: { status: 'active' } ).find_by( id: params[:offer_id] ) if params[:offer_id]
			@offer ||= params[:item_type].constantize.find_by( id: params[:item_id] ).offer if params[:item_type]

			if @offer.nil?
				set_flash "The requested product could not be found.", :danger
				redirect_back fallback_location: '/shop'
				return
			end

			get_or_create_bazaar_cart

			@cart.email = params[:email] if params[:email].present?
			@cart.first_name = params[:first_name] if params[:first_name].present?

			if params[:reset_cart].present?
				@cart.cart_offers.destroy_all
				session[:cart_count] = 0
			end


			quantity = params[:quantity].to_i if params[:quantity].present?
			quantity ||= 1
			quantity = [ quantity, @offer.per_cart_limit ].min if @offer.try(:per_cart_limit).present?

			@cart_offer = @cart.cart_offers.where( offer: @offer ).last
			if @cart_offer.present?

				if params[:replace_offer].present?
					@cart_offer.update( quantity: quantity )
				else
					@cart_offer.increment!( :quantity, quantity )
				end
			else
				@cart_offer = @cart.cart_offers.new(
					offer: @offer,
					quantity: quantity
				)

				if @cart_offer.respond_to?( :source_obj_type ) && @cart_offer.respond_to?( :source_obj_id ) && params[:source_obj_type].present? && params[:source_obj_id].present?
					crypt = ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base[0..31], Rails.application.secrets.secret_key_base)
					@cart_offer.source_obj_id = crypt.decrypt_and_verify(params[:source_obj_id])
					@cart_offer.source_obj_type = crypt.decrypt_and_verify(params[:source_obj_type])
				end

				@cart_offer.source_referrer = request.referrer if @cart_offer.respond_to? :source_referrer
				@cart_offer.source_medium = params[:source_medium] || 'add_to_cart' if @cart_offer.respond_to? :source_medium
				@cart_offer.promotion_id = params[:promotion_id] if params[:promotion_id].present? && @cart_offer.respond_to?(:promotion_id)
				@cart_offer.save

			end

			if params[:remove_offer_id].present? && ( remove_cart_offer = @cart.cart_offers.find_by( offer_id: params[:remove_offer_id] ) ).present?
				remove_cart_offer.destroy
			end

			cart_offer_price = @offer.initial_price
			@cart_offer.update( price: cart_offer_price, subtotal: cart_offer_price * @cart_offer.quantity )

			@cart.update subtotal: @cart.cart_offers.sum( :subtotal )

			session[:cart_count] ||= 0
			session[:cart_count] += quantity


			log_event( { name:'add_cart', on: @offer, content: "added #{@offer} to their cart.", page_params: CGI.unescape( request.query_parameters.merge({ "cart_offer_id" => @cart_offer.id, "cart_id" => @cart.id, "quantity" => @cart_offer.quantity, "offer_id" => @cart_offer.offer_id }).to_query ) } )

			respond_to do |format|
				format.js {
				}
				format.json {
				}
				format.html {
					if params[:buy_now].present? && not( params[:buy_now] == 'solo' && @cart.cart_offers.count > 1 )
						redirect_to bazaar.checkout_index_path( checkout_options.merge( buy_now: 1 ) )
					else
						redirect_to bazaar.cart_path( checkout_options.merge( method: :get ) )
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


			respond_to do |format|
				format.js {
				}
				format.json {
				}
				format.html {
					redirect_back fallback_location: '/admin'
				}
			end
			
		end

		protected
		def checkout_options
			options = default_url_options
			options = options.merge( params[:checkout_options].try(:permit!) || {} )

			if ( funnel = params[:funnel].to_s.gsub(/[^a-zA-Z0-9\-]/,'') ).present?
				options[:funnel] = funnel
			end

			options
		end
	end
end
