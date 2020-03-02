module Bazaar
	class Warehouse < ApplicationRecord
		include FriendlyId
		include Bazaar::WarehouseSearchable if (Bazaar::WarehouseSearchable rescue nil)

		has_many :warehouse_skus
		has_many :warehouse_countries
		has_many :warehouse_states
		has_many :shipments

		belongs_to 	:geo_address, class_name: 'GeoAddress', required: false
		belongs_to 	:user_address, class_name: 'UserAddress', required: false #, required: false

		accepts_nested_attributes_for :geo_address, :warehouse_skus

		enum status: { 'trash' => -1, 'draft' => 0, 'active' => 100 }
		enum country_restriction_type: { 'countries_blacklist' => -1, 'countries_unrestricted' => 0, 'countries_whitelist' => 1 }
		enum state_restriction_type: { 'states_blacklist' => -1, 'states_unrestricted' => 0, 'states_whitelist' => 1 }

		friendly_id :slugger, use: [ :slugged, :history ]
		attr_accessor	:slug_pref

		def self.select_for_state( geo_state, args = {} )
			if geo_state.present?
				warehouses = self.select_for_country( geo_state.geo_country )
				warehouses.select do |warehouse|
					if warehouse.states_unrestricted?
						true
					else
						if warehouse.states_blacklist?
							not( warehouse.warehouse_states.where( geo_state: geo_state ).present? )
						else
							warehouse.warehouse_states.where( geo_state: geo_state ).present?
						end
					end
				end
			elsif args[:geo_country].present?
				warehouses = self.select_for_country( args[:geo_country] )
			else
				self.none
			end
		end

		def self.select_for_country( geo_country )
			self.select do |warehouse|
				if warehouse.countries_unrestricted?
					true
				else
					if warehouse.countries_blacklist?
						not( warehouse.warehouse_countries.where( geo_country: geo_country ).present? )
					else
						warehouse.warehouse_countries.where( geo_country: geo_country ).present?
					end
				end
			end
		end

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
