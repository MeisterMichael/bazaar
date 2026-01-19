module Bazaar
	class SubProduct < Product
		include Bazaar::SubProductSearchable if (Bazaar::ProductSearchable rescue nil)

		belongs_to :parent, required: false, class_name: 'Bazaar::RootProduct'

		def review_source
			contained_products = self.related_products.merge(Bazaar::ProductRelationship.contains)

			if self.parent.blank? && contained_products.present?
				contained_products
			else
				self.root_product
			end
		end

		def root_product
			self.parent || self
		end
	end
end