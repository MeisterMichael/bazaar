module Bazaar
	class ProductRelationship < ApplicationRecord

		# product relationship_type related_product
		# e.g. ProductA contains ProductB

		belongs_to :product, class_name: 'Bazaar::Product', required: true
		belongs_to :related_product, class_name: 'Bazaar::RootProduct', required: true

		enum relationship_type: { 'contains' => 1 }

	end
end