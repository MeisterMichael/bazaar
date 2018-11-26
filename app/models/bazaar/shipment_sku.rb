module Bazaar
	class ShipmentSku < ApplicationRecord
		belongs_to	:shipment
		belongs_to	:sku

		def warehouse_sku
			warehouse = shipment_sku.shipment.warehouse

			if warehouse.present?
				self.sku.warehouse_skus.where( warehouse: warehouse ).first
			else
				nil
			end
		end

	end
end
