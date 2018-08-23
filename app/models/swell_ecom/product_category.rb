module SwellEcom
	class ProductCategory < ApplicationRecord # @todo < Pulitzer::Category

		has_many :products, foreign_key: :category_id

	end
end
