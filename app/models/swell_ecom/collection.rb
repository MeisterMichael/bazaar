module SwellEcom
	class Collection < ActiveRecord::Base
		self.table_name = 'collections'

		has_many :collection_items

		enum status: { 'trash' => -1, 'draft' => 0, 'active' => 1, 'archived' => 2 }
		enum collection_type: { 'list_type' => 1, 'query_type' => 2 }

		def items
			collection_items.collect{ |collection_item| collection_item.item }
		end

	end
end
