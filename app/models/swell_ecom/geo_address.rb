module SwellEcom
	class GeoAddress < ActiveRecord::Base
		self.table_name = 'geo_addresses'

		belongs_to	:geo_state, required: false
		belongs_to	:geo_country
		belongs_to 	:user, required: false

		validates	:first_name, presence: true, allow_blank: false
		validates	:last_name, presence: true, allow_blank: false
		validates	:street, presence: true, allow_blank: false
		validates	:city, presence: true, allow_blank: false
		validates	:zip, presence: true, allow_blank: false

		enum status: { 'active' => 1, 'trash' => 2 }

		def full_name
			"#{self.first_name} #{self.last_name}".strip
		end

		def state_name
			[ self.state, self.geo_state.try(:name) ].select{|str| not( str.blank? ) }.first
		end

		def state_abbrev
			[ self.state, self.geo_state.try(:abbrev) ].select{|str| not( str.blank? ) }.first
		end

		def to_html
			addr = "#{self.full_name}<br>#{self.street}"
			addr = addr + "<br>#{self.street2}" if self.street2.present?
			addr = addr + "<br>#{self.city}, #{self.geo_state.abbrev} #{self.zip}"
			return addr
		end

	end
end
