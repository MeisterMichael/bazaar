module SwellEcom
	class DiscountItem < ActiveRecord::Base
		self.table_name = 'discount_items'

		belongs_to :applies_to, polymorphic: true
		belongs_to :discount

		enum order_item_type: { 'all_order_item_types' => 0, 'prod' => 1, 'tax' => 2, 'shipping' => 3, 'discount' => 4 }
		enum discount_type: { 'percent' => 1, 'fixed' => 2, 'fixed_each' => 3 }

	end
end
