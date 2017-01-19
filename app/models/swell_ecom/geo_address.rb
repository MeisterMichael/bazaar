module SwellEcom
	class GeoAddress < ActiveRecord::Base
		self.table_name = 'geo_addresses'

		belongs_to	:geo_state
		belongs_to	:geo_country
		belongs_to 	:user

		enum status: { 'active' => 1, 'trash' => 2 }

	end
end
