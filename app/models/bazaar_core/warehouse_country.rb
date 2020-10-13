module BazaarCore
	class WarehouseCountry < ApplicationRecord
		belongs_to	:warehouse
		belongs_to	:geo_country
	end
end
