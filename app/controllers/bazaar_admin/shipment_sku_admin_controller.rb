module BazaarAdmin
	class ShipmentSkuAdminController < BazaarAdmin::EcomAdminController

		def create
			@shipment_sku = Bazaar::ShipmentSku.new shipment_sku_params
			authorize( @shipment_sku )


			if @shipment_sku.save
				@shipment_sku.shipment.clear_shipping_carrier_service!

				set_flash "Shipment Sku created"
				if params[:success_redirect_path]
					redirect_to params[:success_redirect_path]
				else
					redirect_back fallback_location: '/admin'
				end
			else
				set_flash "Unable to create shipment sku", :danger, @shipment_sku
				if params[:failure_redirect_path]
					redirect_to params[:failure_redirect_path]
				else
					redirect_back fallback_location: '/admin'
				end
			end
		end

		def destroy
			@shipment_sku = Bazaar::ShipmentSku.find params[:id]

			authorize( @shipment_sku )

			if @shipment_sku.destroy
				@shipment_sku.shipment.clear_shipping_carrier_service!

				if params[:success_redirect_path]
					redirect_to params[:success_redirect_path]
				else
					redirect_back fallback_location: '/admin'
				end
			else
				set_flash "Unable to drop shipment sku", :danger, @shipment_sku
				if params[:failure_redirect_path]
					redirect_to params[:failure_redirect_path]
				else
					redirect_back fallback_location: '/admin'
				end
			end

		end

		protected
		def shipment_sku_params
			shipment_sku_attributes = params.require( :shipment_sku ).permit(
				:shipment_id,
				:sku_id,
				:quantity,
			)

			shipment_sku_attributes
		end

	end
end
