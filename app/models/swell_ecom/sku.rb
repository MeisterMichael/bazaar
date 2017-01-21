module SwellEcom
	class Sku < ActiveRecord::Base
		self.table_name = 'skus'

		belongs_to :product

		def get_tax_code
			self.tax_code || product.tax_code
		end

	end
end
