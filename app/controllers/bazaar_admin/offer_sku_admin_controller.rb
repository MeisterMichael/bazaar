module BazaarAdmin
	class OfferSkuAdminController < BazaarAdmin::EcomAdminController

		before_action :get_offer_sku, except: [:index,:new,:create]

		def create
			authorize( Bazaar::OfferSku )

			@offer_sku = Bazaar::OfferSku.new( offer_sku_params )

			if @offer_sku.save
				set_flash 'Sku Added'
				redirect_back fallback_location: sku_admin_index_path()
			else
				set_flash 'Sku could not be added', :error, @offer_sku
				redirect_back fallback_location: sku_admin_index_path()
			end
		end

		def destroy
			if @offer_sku.trash!
				set_flash "Sku removed", :success
				redirect_back fallback_location: sku_admin_index_path()
			else
				set_flash @offer_sku.errors.full_messages, :danger
				redirect_back fallback_location: sku_admin_index_path()
			end
		end

		def update
			authorize( @offer_sku )

			@offer_sku.attributes = offer_sku_params
			if @offer_sku.save
				set_flash "Offer Sku Updated", :success
			else
				set_flash @offer_sku.errors.full_messages, :danger
			end
			redirect_back fallback_location: sku_admin_index_path()
		end

		protected
		def get_offer_sku
			@offer_sku = Bazaar::OfferSku.find params[:id]
		end

		def offer_sku_params
			params.require(:offer_sku).permit( :parent_obj_id, :parent_obj_type, :sku_id, :quantity, :start_interval, :max_intervals, :apply )
		end

	end
end
