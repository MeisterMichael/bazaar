
module SwellEcom
	class GeoCountry < ApplicationRecord 
		self.table_name = 'geo_countries'
		has_many :geo_states
	end
end