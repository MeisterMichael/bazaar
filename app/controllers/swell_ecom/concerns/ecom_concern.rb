module SwellEcom
	module Concerns

		module EcomConcern
			extend ActiveSupport::Concern

			def get_geo_addresses

				@billing_countries 	||= SwellEcom::GeoCountry.all
				@shipping_countries ||= SwellEcom::GeoCountry.all

				@billing_countries ||= @billing_countries.where( abbrev: SwellEcom.billing_countries[:only] ) if SwellEcom.billing_countries[:only].present?
				@billing_countries ||= @billing_countries.where( abbrev: SwellEcom.billing_countries[:except] ) if SwellEcom.billing_countries[:except].present?

				@shipping_countries ||= @shipping_countries.where( abbrev: SwellEcom.shipping_countries[:only] ) if SwellEcom.shipping_countries[:only].present?
				@shipping_countries ||= @shipping_countries.where( abbrev: SwellEcom.shipping_countries[:except] ) if SwellEcom.shipping_countries[:except].present?

				@billing_states 	||= SwellEcom::GeoState.where( geo_country_id: @order.shipping_address.try(:geo_country_id) || @billing_countries.first.id ) if @billing_countries.count == 1
				@shipping_states	||= SwellEcom::GeoState.where( geo_country_id: @order.billing_address.try(:geo_country_id) || @shipping_countries.first.id ) if @shipping_countries.count == 1

			end

			def get_billing_countries
				get_geo_addresses
				@billing_countries
			end

			def get_shipping_countries
				get_geo_addresses
				@shipping_countries
			end

			def get_billing_states
				get_geo_addresses
				@billing_states
			end

			def get_shipping_states
				get_geo_addresses
				@shipping_states
			end

		end
	end
end
