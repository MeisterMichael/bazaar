module Bazaar
	class Shipment < ApplicationRecord
		include Bazaar::Concerns::MoneyAttributesConcern

		belongs_to	:order, required: false
		belongs_to	:destination_address, class_name: 'GeoAddress', validate: true, required: false
		belongs_to	:source_address, required: false
		belongs_to	:warehouse, required: false

		has_many :shipment_logs
		has_many :shipment_skus

		enum status: { 'canceled' => -1, 'pending' => 0, 'picking' => 100, 'packed' => 200, 'shipped' => 300, 'delivered' => 400, 'returned' => 500 }
		enum package_shape: { 'no_shape' => 0, 'letter' => 1, 'box' => 2, 'cylinder' => 3 }

		validate :validate_warehouse_skus

		money_attributes :cost

		protected
		def validate_warehouse_skus
			if self.warehouse.present?
				self.shipment_skus.each do |shipment_sku|
					warehouse_sku = shipment_sku.warehouse_sku

					self.errors.add :base, "Warehouse '#{warehouse_sku.warehouse.name}' does not support the sku #{shipment_sku.sku.code}") unless warehouse_sku.present? && warehouse_sku.code.present?
				end
			end
		end

	end
end
