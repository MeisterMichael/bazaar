module Bazaar
	class SkuCountry < ApplicationRecord
		belongs_to	:sku
		belongs_to	:geo_country
	end
end
