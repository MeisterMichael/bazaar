module SwellEcom
	class OrderItem < ActiveRecord::Base
		self.table_name = 'order_items'
		include SwellEcom::Concerns::MoneyAttributesConcern

		enum order_item_type: { 'prod' => 1, 'tax' => 2, 'shipping' => 3, 'discount' => 4 }

		belongs_to :item, polymorphic: true, required: false
		belongs_to :order

		belongs_to :subscription, required: false, validate: true

		money_attributes :subtotal, :price

	end
end
