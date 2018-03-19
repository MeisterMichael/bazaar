module SwellEcom
	class CollectionItem < ActiveRecord::Base
		self.table_name = 'collection_items'

		belongs_to :collection
		belongs_to :item, polymorphic: true

	end
end
