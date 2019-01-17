module Bazaar
	class Collection < ApplicationRecord

		include Bazaar::CollectionSearchable if (Bazaar::CollectionSearchable rescue nil)

		has_many :collection_items

		enum status: { 'trash' => -1, 'draft' => 0, 'active' => 1, 'archived' => 2 }
		enum collection_type: { 'list_type' => 1, 'query_type' => 2 }
		enum availability: { 'hidden' => 0, 'anyone' => 1 }

		def items
			collection_items.collect(&:item)
		end

	end
end
