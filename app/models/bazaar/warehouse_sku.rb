module Bazaar
	class WarehouseSku < ApplicationRecord
		belongs_to	:warehouse
		belongs_to	:sku

		enum status: { 'disabled' => -100, 'active' => 100 }
	end
end
