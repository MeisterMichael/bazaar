module SwellEcom
	class GeoAddress < ActiveRecord::Base
		self.table_name = 'geo_addresses'

		belongs_to	:geo_state
		belongs_to	:geo_country
		belongs_to 	:user

		enum status: { 'active' => 1, 'trash' => 2 }

		def full_name
			"#{self.first_name} #{self.last_name}".strip
		end

	end
end
