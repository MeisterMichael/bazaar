module Bazaar
	class SubProduct < Product
		belongs_to :parent, required: false, class_name: 'Bazaar::RootProduct'

	end
end