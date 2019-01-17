module Bazaar
	class WarehouseState < ApplicationRecord
		belongs_to	:warehouse
		belongs_to	:geo_state
	end
end
