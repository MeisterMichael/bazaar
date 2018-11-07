module Bazaar
	class ShipmentSku < ApplicationRecord
		belongs_to	:shipment
		belongs_to	:sku
	end
end
