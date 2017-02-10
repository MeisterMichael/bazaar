module SwellEcom
	class ProductOption < ActiveRecord::Base
		self.table_name = 'product_options'

		belongs_to :product

	end
end
