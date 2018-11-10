module Bazaar
	class WarehouseSkuAdminController < Bazaar::EcomAdminController
		before_action :get_warehouse_sku, except: [:index,:new,:create]

		def create
			authorize( Bazaar::WarehouseSku )

			@warehouse_sku = Bazaar::WarehouseSku.new( warehouse_sku_params )

			if @warehouse_sku.save
				set_flash 'Sku added'
				redirect_back fallback_location: edit_warehouse_admin_path( @warehouse_sku.warehouse )
			else
				set_flash 'Sku could not be added', :error, @warehouse_sku
				redirect_back fallback_location: edit_warehouse_admin_path( @warehouse_sku.warehouse )
			end
		end

		def destroy
			authorize( @warehouse_sku )

			if @warehouse_sku.destroy
				set_flash 'Sku removed'
				redirect_back fallback_location: edit_warehouse_admin_path( @warehouse_sku.warehouse )
			else
				set_flash 'Sku could not be removed', :error, @warehouse_sku
				redirect_back fallback_location: edit_warehouse_admin_path( @warehouse_sku.warehouse )
			end

		end

		def edit
			@redirect_to = params[:redirect_to] || request.referrer
		end

		def update
			@warehouse_sku.attributes = warehouse_sku_params
			authorize( @warehouse_sku )


			if @warehouse_sku.save
				set_flash 'Sku updated'
				redirect_to (params[:redirect_to] || edit_warehouse_admin_path( @warehouse_sku.warehouse ))
			else
				set_flash 'Sku update failed', :error, @warehouse_sku
				redirect_back fallback_location: edit_warehouse_sku_admin_path( @warehouse_sku )
			end

		end

		protected

		def get_warehouse_sku
			@warehouse_sku = Bazaar::WarehouseSku.find(params[:id])
		end

		def warehouse_sku_params
			params.require(:warehouse_sku).permit( :warehouse_id, :sku_id, :sku, :quantity, :status, :priority )
		end


	end
end
