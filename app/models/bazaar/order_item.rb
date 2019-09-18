module Bazaar
	class OrderItem < ApplicationRecord

		include Bazaar::Concerns::MoneyAttributesConcern
		include SwellId::Concerns::PolymorphicIdentifiers

		enum order_item_type: { 'prod' => 1, 'tax' => 2, 'shipping' => 3, 'discount' => 4 }

		belongs_to :item, polymorphic: true, required: false
		belongs_to :order

		belongs_to :subscription, required: false, validate: true

		money_attributes :subtotal, :price


	end
end
