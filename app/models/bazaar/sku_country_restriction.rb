module Bazaar
	class SkuCountryRestriction < ApplicationRecord
		belongs_to	:sku
		belongs_to	:geo_country
	end
end
