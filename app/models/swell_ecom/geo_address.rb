module SwellEcom
	class GeoAddress < ApplicationRecord
		self.table_name = 'geo_addresses'

		before_save :set_hash_code

		belongs_to	:geo_state, required: false
		belongs_to	:geo_country
		belongs_to 	:user, required: false

		validates	:first_name, presence: true, allow_blank: false
		validates	:last_name, presence: true, allow_blank: false
		validates	:street, presence: true, allow_blank: false
		validates	:city, presence: true, allow_blank: false
		validates	:zip, presence: true, allow_blank: false

		enum status: { 'active' => 1, 'trash' => 2 }

		acts_as_taggable_array_on :tags

		def calculate_hash_code
			self.class.calculate_hash_code( self )
		end

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
			addr = addr + "<br>#{self.city}, #{self.state_abbrev} #{self.zip}"
			addr = addr + "<br>#{self.geo_country.try(:name)}"
			return addr
		end

		def self.calculate_hash_code( geo_address )
			"#{(geo_address.street || '').strip.downcase.gsub(/[^A-Za-z0-9]/,'')};#{(geo_address.street2 || '').strip.downcase.gsub(/[^A-Za-z0-9]/,'')};#{(geo_address.zip || '').strip.downcase.gsub(/[^A-Za-z0-9]/,'')};#{(geo_address.city || '').strip.downcase.gsub(/[^A-Za-z0-9]/,'')};#{(geo_address.state_abbrev || '').strip.downcase.gsub(/[^A-Za-z0-9]/,'')};#{geo_address.geo_country.abbrev.strip.downcase.gsub(/[^A-Za-z0-9]/,'')}"
		end

		def self.with_same_user
			self.where( user: self.user )
		end

		def self.with_same_hash_code
			self.where( hash_code: calculate_hash_code )
		end

		protected
		def set_hash_code
			if self.respond_to? :hash_code
				self.hash_code = self.calculate_hash_code()
			end
		end

	end
end
