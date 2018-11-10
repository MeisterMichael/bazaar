module Bazaar
	class SkuCountryAdminController < Bazaar::EcomAdminController
		before_action :get_sku_country, except: [:index,:new,:create]

		def create
			authorize( Bazaar::SkuCountry )

			@sku_country = Bazaar::SkuCountry.new( sku_country_params )

			if @sku_country.save
				set_flash 'Country added'
				redirect_back fallback_location: edit_sku_admin_path( @sku_country.sku )
			else
				set_flash 'Country could not be added', :error, @sku_country
				redirect_back fallback_location: edit_sku_admin_path( @sku_country.sku )
			end
		end

		def destroy
			authorize( @sku_country )

			if @sku_country.destroy
				set_flash 'Country removed'
				redirect_back fallback_location: edit_sku_admin_path( @sku_country.sku )
			else
				set_flash 'Country could not be removed', :error, @sku_country
				redirect_back fallback_location: edit_sku_admin_path( @sku_country.sku )
			end

		end

		protected

		def get_sku_country
			@sku_country = Bazaar::SkuCountry.find(params[:id])
		end

		def sku_country_params
			params.require(:sku_country).permit( :sku_id, :geo_country_id, :geo_country )
		end


	end
end
