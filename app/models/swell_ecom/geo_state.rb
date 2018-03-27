
module SwellEcom
	class GeoState < ApplicationRecord 
		self.table_name = 'geo_states'

		belongs_to :geo_country
		has_one :tax_rate

	end
end
