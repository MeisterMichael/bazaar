module Bazaar
	class OfferPriceAdminController < Bazaar::EcomAdminController

		before_action :get_offer_price, except: [:index,:new,:create]

		def create
			authorize( Bazaar::OfferPrice )

			@offer_price = Bazaar::OfferPrice.new( offer_price_params )

			if params[:replace] == 'duplicate_start_intervals'
				sibling_offer_prices = @offer_price.parent_obj.offer_prices.active
				sibling_offer_prices = sibling_offer_prices.where( start_interval: @offer_price.start_interval )
				sibling_offer_prices.update( status: 'trash' )
			end

			if @offer_price.save
				set_flash 'Price Added'
				redirect_back fallback_location: sku_admin_index_path()
			else
				set_flash 'Price could not be added', :error, @offer_price
				redirect_back fallback_location: sku_admin_index_path()
			end
		end

		def destroy
			if @offer_price.trash!
				set_flash "Price removed", :success
				redirect_back fallback_location: sku_admin_index_path()
			else
				set_flash @offer_price.errors.full_messages, :danger
				redirect_back fallback_location: sku_admin_index_path()
			end
		end

		def edit
			authorize( @offer_price )
		end

		def update
			authorize( @offer_price )

			@new_offer_price = Bazaar::OfferPrice.new(
				parent_obj_type: @offer_price.parent_obj_type,
				parent_obj_id: @offer_price.parent_obj_id,
				start_interval: @offer_price.start_interval,
				max_intervals: @offer_price.max_intervals,
				price: @offer_price.price,
				status: @offer_price.status,
				properties: @offer_price.properties,
			)

			@offer_price.status = 'trash'
			@new_offer_price.attributes = offer_price_params

			if @offer_price.save

				if @new_offer_price.save
					set_flash "Offer Price Updated", :success
				else
					set_flash @new_offer_price.errors.full_messages, :danger
				end

			else
				set_flash @offer_price.errors.full_messages, :danger
			end

			redirect_to edit_offer_admin_path( @new_offer_price.parent_obj )
		end

		protected
		def get_offer_price
			@offer_price = Bazaar::OfferPrice.find params[:id]
		end

		def offer_price_params
			params.require(:offer_price).permit( :parent_obj_type, :parent_obj_id, :start_interval, :max_intervals, :price, :price_as_money_string, :price_as_money, :status, :trashed_at )
		end


	end
end
