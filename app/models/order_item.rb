module SwellEcom
	class OrderItem < ActiveRecord::Base 
		self.table_name = 'order_items'

		belongs_to :item, polymorphic: true

	end
end
