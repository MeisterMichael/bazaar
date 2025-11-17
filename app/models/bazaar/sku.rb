module Bazaar
	class Sku < ApplicationRecord
		include Bazaar::Concerns::MoneyAttributesConcern
		include Bazaar::SkuSearchable if (Bazaar::SkuSearchable rescue nil)
		include SwellId::Concerns::MultiIdentifierConcern if (SwellId::Concerns::MultiIdentifierConcern rescue nil)

		belongs_to	:product, required: false

		has_many	:offer_skus
		has_many	:offers, through: :offer_skus, source: :parent_obj, source_type: 'Bazaar::Offer'
		has_many	:shipment_skus
		has_many	:shipments, through: :shipment_skus
		has_many	:sku_countries
		has_many	:warehouse_skus
		has_many	:warehouses, through: :warehouse_skus
		has_many	:wholesale_items
		has_many	:wholesale_profiles, through: :wholesale_items

		acts_as_taggable_array_on :tags

		has_one_attached :avatar_attachment

		enum status: { 'trash' => -1, 'draft' => 0, 'active' => 100 }
		enum country_restriction_type: { 'countries_blacklist' => -1, 'countries_unrestricted' => 0, 'countries_whitelist' => 1 }
		enum state_restriction_type: { 'states_blacklist' => -1, 'states_unrestricted' => 0, 'states_whitelist' => 1 }
		enum shape: { 'no_shape' => 0, 'letter' => 1, 'box' => 2, 'cylinder' => 3 }

		money_attributes :sku_cost, :sku_value



		def gtins_csv
			self.gtins.join(',')
		end

		def gtins_csv=(gtins_csv)
			self.gtins = gtins_csv.split(/,\s*/)
		end

		def mpns_csv
			self.mpns.join(',')
		end

		def mpns_csv=(mpns_csv)
			self.mpns = mpns_csv.split(/,\s*/)
		end

		def tags_csv
			self.tags.join(',')
		end

		def tags_csv=(tags_csv)
			self.tags = tags_csv.split(/,\s*/)
		end

		def to_s
			if self.name.blank?
				self.code
			else
				"#{self.name} (#{self.code})"
			end
		end
	end
end
