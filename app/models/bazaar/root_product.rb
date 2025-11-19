module Bazaar
	class RootProduct < Product
		include Bazaar::RootProductSearchable if (Bazaar::RootProductSearchable rescue nil)

		has_many :sub_products, foreign_key: :parent_id, class_name: 'Bazaar::SubProduct'
		has_many :skus, foreign_key: :product_id

	end
end