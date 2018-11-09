module Bazaar
	class WarehouseCountryAdminController < Bazaar::EcomAdminController
		before_action :get_warehouse_country, except: [:index,:new,:create]

		def create
			authorize( Bazaar::WarehouseCountry )

			@warehouse_country = Bazaar::WarehouseCountry.new( warehouse_country_params )

			if @warehouse_country.save
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
