module BazaarAdmin
	class WarehouseStateAdminController < BazaarAdmin::EcomAdminController
		before_action :get_warehouse_state, except: [:index,:new,:create]

		def create
			authorize( BazaarCore::WarehouseState )

			@warehouse_state = BazaarCore::WarehouseState.new( warehouse_state_params )

			if @warehouse_state.save

				log_event( { name:'warehouse_update', category: 'admin', on: @warehouse_state.warehouse, content: "added warehouse state filter #{@warehouse_state.geo_state.abbrev} to warehouse #{@warehouse_state.warehouse.name}." } )

				set_flash 'State added'
				redirect_back fallback_location: edit_warehouse_admin_path( @warehouse_state.warehouse )
			else
				set_flash 'State could not be added', :error, @warehouse_state
				redirect_back fallback_location: edit_warehouse_admin_path( @warehouse_state.warehouse )
			end
		end

		def destroy
			authorize( @warehouse_state )

			if @warehouse_state.destroy
				log_event( { name:'warehouse_update', category: 'admin', on: @warehouse_state.warehouse, content: "removed warehouse state filter #{@warehouse_state.geo_state.abbrev} from warehouse #{@warehouse_state.warehouse.name}." } )

				set_flash 'State removed'
				redirect_back fallback_location: edit_warehouse_admin_path( @warehouse_state.warehouse )
			else
				set_flash 'State could not be removed', :error, @warehouse_state
				redirect_back fallback_location: edit_warehouse_admin_path( @warehouse_state.warehouse )
			end

		end

		protected

		def get_warehouse_state
			@warehouse_state = BazaarCore::WarehouseState.find(params[:id])
		end

		def warehouse_state_params
			params.require(:warehouse_state).permit( :warehouse_id, :geo_state_id, :geo_state )
		end


	end
end
