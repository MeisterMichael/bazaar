module SwellEcom
	class Sku < ActiveRecord::Base
		self.table_name = 'skus'

		belongs_to :product

		def tax_code
			20010 #product.tax_code
		end

	end
end
