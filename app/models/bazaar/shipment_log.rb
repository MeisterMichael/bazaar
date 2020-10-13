module Bazaar
	class ShipmentLog < ApplicationRecord
		belongs_to	:shipment
	end
end
