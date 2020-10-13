module BazaarCore
	class WarehouseSkuCountry < ApplicationRecord
		belongs_to	:warehouse_sku
		belongs_to	:geo_country
	end
end
