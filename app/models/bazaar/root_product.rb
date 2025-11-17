module Bazaar
	class RootProduct < Product
		has_many :sub_products, foreign_key: :parent_id, class_name: 'Bazaar::SubProduct'
		has_many :skus, foreign_key: :product_id

	end
end