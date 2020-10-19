module BazaarCore
	class ProductCategory < Pulitzer::Category
		include BazaarCore::ProductCategorySearchable if (BazaarCore::ProductCategorySearchable rescue nil)

		has_many :products, foreign_key: :category_id

	end
end
