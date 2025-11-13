module Bazaar
	class RootProduct < Product
		has_many :sub_products, foreign_key: :parent_id, class_name: 'Bazaar::SubProduct'

	end
end