module Bazaar
	class Warehouse < ApplicationRecord
		include FriendlyId

		has_many :warehouse_skus
		has_many :warehouse_countries
		has_many :shipments

		belongs_to 	:geo_address, class_name: 'GeoAddress', required: false

		accepts_nested_attributes_for :geo_address, :warehouse_skus

		enum status: { 'trash' => -1, 'draft' => 0, 'active' => 100 }
		enum restriction_type: { 'blacklist' => -1, 'unrestricted' => 0, 'whitelist' => 1 }

		friendly_id :slugger, use: [ :slugged, :history ]
		attr_accessor	:slug_pref

		protected
		def slugger
			if self.slug_pref.present?
				self.slug = nil # friendly_id 5.0 only updates slug if slug field is nil
				return self.slug_pref
			else
				return self.name
			end
		end
	end
end
