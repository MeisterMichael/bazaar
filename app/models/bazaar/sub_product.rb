module Bazaar
	class SubProduct < Product
		include Bazaar::SubProductSearchable if (Bazaar::ProductSearchable rescue nil)

		belongs_to :parent, required: false, class_name: 'Bazaar::RootProduct'

	end
end