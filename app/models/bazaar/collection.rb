module Bazaar
	class Collection < ApplicationRecord

		include SwellId::Concerns::PolymorphicIdentifiers
		include Bazaar::CollectionSearchable if (Bazaar::CollectionSearchable rescue nil)
		include FriendlyId

		has_many :collection_items

		enum status: { 'trash' => -1, 'draft' => 0, 'active' => 1, 'archived' => 2 }
		enum collection_type: { 'list_type' => 1, 'query_type' => 2 }
		enum availability: { 'hidden' => 0, 'anyone' => 1 }

		accepts_nested_attributes_for :collection_items, allow_destroy: true

		friendly_id :slugger, use: [ :slugged, :history ]
		attr_accessor	:slug_pref

		def items
			collection_items.collect(&:item)
		end


		protected
		def slugger
			if self.slug_pref.present?
				self.slug = nil # friendly_id 5.0 only updates slug if slug field is nil
				return self.slug_pref
			else
				return self.title
			end
		end

	end
end
