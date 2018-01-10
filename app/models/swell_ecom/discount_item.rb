module SwellEcom
	class DiscountItem < ActiveRecord::Base
		self.table_name = 'discount_items'

		belongs_to :applies_to, polymorphic: true
		belongs_to :discount

		enum order_item_type: { 'prod' => 1, 'tax' => 2, 'shipping' => 3, 'discount' => 4 }

	end
end
