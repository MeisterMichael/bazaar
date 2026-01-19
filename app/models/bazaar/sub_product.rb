module Bazaar
	class SubProduct < Product
		include Bazaar::SubProductSearchable if (Bazaar::ProductSearchable rescue nil)

		belongs_to :parent, required: false, class_name: 'Bazaar::RootProduct'

		def review_source
			if root_product.present?
				root_product
			else
				related_products.merge(Bazaar::ProductRelationship.contains)
			end
		end

		def root_product
			self.parent || self
		end
	end
end