module BazaarCore
	class WarehouseSku < ApplicationRecord
		belongs_to	:warehouse
		belongs_to	:sku
		has_many		:warehouse_sku_countries

		enum status: { 'disabled' => -100, 'active' => 100 }
		enum country_restriction_type: { 'countries_blacklist' => -1, 'countries_unrestricted' => 0, 'countries_whitelist' => 1 }
		enum state_restriction_type: { 'states_blacklist' => -1, 'states_unrestricted' => 0, 'states_whitelist' => 1 }

		def code
			self.warehouse_code || self.sku.try(:code)
		end
	end
end
