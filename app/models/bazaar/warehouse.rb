module Bazaar
	class Warehouse < ApplicationRecord

		has_many :warehouse_skus
		has_many :warehouse_countries
		has_many :shipments
		has_one :geo_address

		accepts_nested_attributes_for :geo_address, :warehouse_skus

		enum status: { 'draft' => 0, 'active' => 100 }
		enum restriction_type: { 'blacklist' => -1, 'unrestricted' => 0, 'whitelist' => 1 }

	end
end
