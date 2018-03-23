module SwellEcom
	class CollectionItem < ApplicationRecord
		self.table_name = 'collection_items'

		belongs_to :collection
		belongs_to :item, polymorphic: true

	end
end
