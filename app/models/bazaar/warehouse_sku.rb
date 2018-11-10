module Bazaar
	class WarehouseSku < ApplicationRecord
		belongs_to	:warehouse
		belongs_to	:sku
		has_many		:warehouse_sku_countries

		enum status: { 'disabled' => -100, 'active' => 100 }
		enum restriction_type: { 'blacklist' => -1, 'unrestricted' => 0, 'whitelist' => 1 }
	end
end
