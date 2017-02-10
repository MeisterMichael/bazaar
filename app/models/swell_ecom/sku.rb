module SwellEcom
	class Sku < ActiveRecord::Base
		self.table_name = 'skus'

		enum status: { 'draft' => 0, 'active' => 1, 'archive' => 2, 'trash' => 3 }

		belongs_to :product

		def get_tax_code
			self.tax_code || product.tax_code
		end

	end
end
