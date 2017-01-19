module SwellEcom
	class Sku < ActiveRecord::Base 
		self.table_name = 'skus'

		belongs_to :product
	end
end