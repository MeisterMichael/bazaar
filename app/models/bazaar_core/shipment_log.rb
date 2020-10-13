module BazaarCore
	class ShipmentLog < ApplicationRecord
		belongs_to	:shipment
	end
end
