module SwellEcom
	class ProductCategory < SwellMedia::Category

		has_many :products, foreign_key: :category_id

	end
end
