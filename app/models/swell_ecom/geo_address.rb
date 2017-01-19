module SwellEcom
	class GeoAddress < ActiveRecord::Base
		self.table_name = 'geo_addresses'

		belongs_to :geo_state
		belongs_to :user

	end
end
