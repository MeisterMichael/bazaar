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

		def to_html
			addr = "#{self.full_name}<br>#{self.street}"
			addr = addr + "<br>#{self.street2}" if self.street2.present?
			addr = addr + "<br>#{self.city}, #{self.geo_state.abbrev} #{self.zip}"
			return addr
		end

	end
end
