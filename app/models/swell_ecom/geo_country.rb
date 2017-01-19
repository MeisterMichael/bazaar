
module SwellEcom
	class GeoCountry < ActiveRecord::Base 
		self.table_name = 'geo_countries'
		has_many :geo_states
	end
end