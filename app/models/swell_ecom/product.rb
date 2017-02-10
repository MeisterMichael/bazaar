module SwellEcom
	class Product < ActiveRecord::Base
		self.table_name = 'products'

		enum status: { 'draft' => 0, 'active' => 1, 'archive' => 2, 'trash' => 3 }

		validates		:title, presence: true, unless: :allow_blank_title?

		include SwellMedia::Concerns::URLConcern
		include SwellMedia::Concerns::AvatarAsset
		include SwellMedia::Concerns::TagArrayConcern
		#include SwellMedia::Concerns::ExpiresCache

		mounted_at '/store'

		has_many :product_options
		has_many :skus
		
		before_save	:set_publish_at

		attr_accessor	:slug_pref

		include FriendlyId
		friendly_id :slugger, use: [ :slugged, :history ]

		acts_as_taggable_array_on :tags


		def self.published( args = {} )
			where( "products.publish_at <= :now", now: Time.zone.now ).active
		end

		def published?
			active? && publish_at < Time.zone.now
		end



		def slugger
			if self.slug_pref.present?
				self.slug = nil # friendly_id 5.0 only updates slug if slug field is nil
				return self.slug_pref
			else
				return self.title
			end
		end

		def tags_csv
			self.tags.join(',')
		end

		def tags_csv=(tags_csv)
			self.tags = tags_csv.split(/,\s*/)
		end


		private
			def allow_blank_title?
				self.slug_pref.present?
			end

			def set_publish_at
				# set publish_at
				self.publish_at ||= Time.zone.now
			end


	end
end
