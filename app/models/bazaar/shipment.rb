module Bazaar
	class Shipment < ApplicationRecord
		include Bazaar::Concerns::MoneyAttributesConcern
		include Bazaar::ShipmentSearchable if (Bazaar::ShipmentSearchable rescue nil)

		belongs_to	:user, required: false
		belongs_to	:order, required: false
		belongs_to	:destination_address, class_name: 'GeoAddress', validate: true, required: false
		belongs_to	:source_address, required: false
		belongs_to	:warehouse, required: false

		has_many :shipment_logs
		has_many :shipment_skus
		has_many :skus, through: :shipment_skus

		enum status: { 'rejected' => -100, 'canceled' => -1, 'pending' => 0, 'picking' => 100, 'packed' => 200, 'shipped' => 300, 'delivered' => 400, 'returned' => 500, 'review' => 900, 'hold_review' => 950 }
		enum package_shape: { 'no_shape' => 0, 'letter' => 1, 'box' => 2, 'cylinder' => 3 }

		validate :validate_warehouse_skus

		money_attributes :cost

		protected
		def validate_warehouse_skus
			if self.warehouse.present?
				self.shipment_skus.each do |shipment_sku|
					warehouse_sku = shipment_sku.warehouse_sku

					unless warehouse_sku.present? && warehouse_sku.code.present?
						self.errors.add( :base, "Warehouse '#{self.try(:warehouse).try(:name)}' does not support the sku #{shipment_sku.sku.code}")
					end
				end
			end
		end

	end
end
