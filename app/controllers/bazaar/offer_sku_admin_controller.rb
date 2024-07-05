module Bazaar
	class OfferSkuAdminController < Bazaar::EcomAdminController

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

		def edit
			authorize( @offer_sku )
		end

		def update
			authorize( @offer_sku )

			@new_offer_sku = Bazaar::OfferSku.new(
				parent_obj_type: @offer_sku.parent_obj_type,
				parent_obj_id: @offer_sku.parent_obj_id,
				start_interval: @offer_sku.start_interval,
				max_intervals: @offer_sku.max_intervals,
				quantity: @offer_sku.quantity,
				shipping_exemptions: @offer_sku.shipping_exemptions,
				status: @offer_sku.status,
				properties: @offer_sku.properties,
			)

			@offer_sku.status = 'trash'
			@new_offer_sku.attributes = offer_sku_params

			if @offer_sku.save

				if @new_offer_sku.save
					set_flash "Offer Sku Updated", :success
				else
					set_flash @new_offer_sku.errors.full_messages, :danger
				end

			else
				set_flash @offer_sku.errors.full_messages, :danger
			end

			redirect_to edit_offer_admin_path( @new_offer_sku.parent_obj )
		end

		protected
		def get_offer_sku
			@offer_sku = Bazaar::OfferSku.find params[:id]
		end

		def offer_sku_params
			params.require(:offer_sku).permit( :parent_obj_id, :parent_obj_type, :sku_id, :shipping_exemptions, :quantity, :start_interval, :max_intervals, :apply )
		end

	end
end
