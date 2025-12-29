module Bazaar
	class SubProduct < Product
		include Bazaar::SubProductSearchable if (Bazaar::ProductSearchable rescue nil)

		belongs_to :parent, required: false, class_name: 'Bazaar::RootProduct'

		def review_source
			root_product
		end

		def root_product
			self.parent || self
		end
	end
end