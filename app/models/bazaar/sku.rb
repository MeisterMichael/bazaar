module Bazaar
	class Sku < ApplicationRecord
		include Bazaar::Concerns::MoneyAttributesConcern

		has_many	:offer_skus
		has_many	:warehouse_skus
		has_many	:shipment_skus
		has_many	:shipments, through: :shipment_skus
		has_many	:sku_countries
		has_many	:offer_skus

		enum status: { 'trash' => -1, 'draft' => 0, 'active' => 100 }
		enum country_restriction_type: { 'countries_blacklist' => -1, 'countries_unrestricted' => 0, 'countries_whitelist' => 1 }
		enum state_restriction_type: { 'states_blacklist' => -1, 'states_unrestricted' => 0, 'states_whitelist' => 1 }
		enum package_shape: { 'no_shape' => 0, 'letter' => 1, 'box' => 2, 'cylinder' => 3 }

		money_attributes :sku_cost, :sku_value

		def to_s
			if self.name.blank?
				self.code
			else
				"#{self.name} (#{self.code})"
			end
		end
	end
end
