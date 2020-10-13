module Bazaar
	class ProductCategory < Pulitzer::Category
		include Bazaar::ProductCategorySearchable if (Bazaar::ProductCategorySearchable rescue nil)

		has_many :products, foreign_key: :category_id

	end
end
