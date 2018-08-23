module SwellEcom
	class ProductCategory < Pulitzer::Category

		has_many :products, foreign_key: :category_id

	end
end
