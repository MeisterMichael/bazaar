module Bazaar
	class WarehouseCountryAdminController < Bazaar::EcomAdminController
		before_action :get_warehouse_country, except: [:index,:new,:create]

		def create
			authorize( Bazaar::WarehouseCountry )

			@warehouse_country = Bazaar::WarehouseCountry.new( warehouse_country_params )

			if @warehouse_country.save

				log_event( { name:'warehouse_update', category: 'admin', on: @warehouse_country.warehouse, content: "added warehouse country filter #{@warehouse_country.geo_country.abbrev} to warehouse #{@warehouse_country.warehouse.name}." } )

				set_flash 'Country added'
				redirect_back fallback_location: edit_warehouse_admin_path( @warehouse_country.warehouse )
			else
				set_flash 'Country could not be added', :error, @warehouse_country
				redirect_back fallback_location: edit_warehouse_admin_path( @warehouse_country.warehouse )
			end
		end

		def destroy
			authorize( @warehouse_country )

			if @warehouse_country.destroy
				log_event( { name:'warehouse_update', category: 'admin', on: @warehouse_country.warehouse, content: "removed warehouse country filter #{@warehouse_country.geo_country.abbrev} from warehouse #{@warehouse_country.warehouse.name}." } )

				set_flash 'Country removed'
				redirect_back fallback_location: edit_warehouse_admin_path( @warehouse_country.warehouse )
			else
				set_flash 'Country could not be removed', :error, @warehouse_country
				redirect_back fallback_location: edit_warehouse_admin_path( @warehouse_country.warehouse )
			end

		end

		protected

		def get_warehouse_country
			@warehouse_country = Bazaar::WarehouseCountry.find(params[:id])
		end

		def warehouse_country_params
			params.require(:warehouse_country).permit( :warehouse_id, :geo_country_id, :geo_country )
		end


	end
end
