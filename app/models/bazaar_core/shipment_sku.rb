module BazaarCore
	class ShipmentSku < ApplicationRecord
		belongs_to	:shipment
		belongs_to	:sku

		def warehouse_sku
			warehouse = self.shipment.warehouse

			if warehouse.present?
				self.sku.warehouse_skus.active.where( warehouse: warehouse ).first
			else
				nil
			end
		end

	end
end
