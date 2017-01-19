module SwellEcom
	class Plan < ActiveRecord::Base
		# Subscription version of a sku

		self.table_name = 'plans'
		self.belongs_to :product

	end
end
