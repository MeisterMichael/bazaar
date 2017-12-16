module SwellEcom
	class OrderItem < ActiveRecord::Base
		self.table_name = 'order_items'

		belongs_to :item, polymorphic: true, required: false
		belongs_to :order

		belongs_to :subscription, required: false

		enum order_item_type: { 'prod' => 1, 'tax' => 2, 'shipping' => 3, 'discount' => 4 }

	end
end
