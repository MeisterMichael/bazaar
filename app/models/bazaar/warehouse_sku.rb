module Bazaar
	class WarehouseSku < ApplicationRecord
		belongs_to	:warehouse
		belongs_to	:sku
	end
end
