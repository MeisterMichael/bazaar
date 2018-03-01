module SwellEcom
	module Concerns

		module EcomConcern
			extend ActiveSupport::Concern

			def get_geo_addresses

				@billing_countries 	||= SwellEcom::GeoCountry.where( bill_to: true )
				@shipping_countries ||= SwellEcom::GeoCountry.where( ship_to: true )

				@billing_states 	||= SwellEcom::GeoState.all
				@shipping_states	||= SwellEcom::GeoState.all
				@billing_states 	||= SwellEcom::GeoState.where( geo_country_id: @billing_countries.first.id ) if @billing_countries.count == 1
				@shipping_states	||= SwellEcom::GeoState.where( geo_country_id: @shipping_countries.first.id ) if @shipping_countries.count == 1

			end

			def get_billing_countries
				get_geo_addresses
				@billing_countries
			end

			def get_shipping_countries
				get_geo_addresses
				@shipping_countries
			end

			def get_billing_states( geo_country_id )
				get_geo_addresses
				if geo_country_id.present?
					@billing_states.where( geo_country_id: geo_country_id )
				else
					SwellEcom::GeoState.none
				end
			end

			def get_shipping_states( geo_country_id )
				get_geo_addresses
				if geo_country_id.present?
					@shipping_states.where( geo_country_id: geo_country_id )
				else
					SwellEcom::GeoState.none
				end
			end

		end
	end
end
