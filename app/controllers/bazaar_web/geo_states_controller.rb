
module BazaarWeb
	class GeoStatesController < ApplicationController
		include Bazaar::Concerns::EcomConcern

		def index
			@address_attribute = params[:address_attribute] || params[:addressAttribute] || params['address-attribute']

			if @address_attribute == 'billing_address'
				@states = get_billing_states( params[:geo_country_id] )
			elsif @address_attribute == 'shipping_address'
				@states = get_shipping_states( params[:geo_country_id] )
			else
				@states = GeoState.where( geo_country_id: params[:geo_country_id] )
			end




		end


	end
end
