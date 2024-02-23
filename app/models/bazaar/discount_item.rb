module Bazaar
	class DiscountItem < ApplicationRecord
		include SwellId::Concerns::PolymorphicIdentifiers
		include Bazaar::Concerns::MoneyAttributesConcern
		
		money_attributes :discount_amount

		acts_as_taggable_array_on :tags

		enum order_item_type: { 'all_order_item_types' => 0, 'prod' => 1, 'tax' => 2, 'shipping' => 3, 'discount' => 4 }
		enum discount_type: { 'percent' => 1, 'fixed' => 2, 'fixed_each' => 3 }

		belongs_to :applies_to, polymorphic: true, required: false
		belongs_to :discount

		validates :minimum_orders, presence: true, numericality: { greater_than_or_equal_to: 0 }, allow_blank: false
		validates :maximum_orders, presence: true, numericality: { greater_than_or_equal_to: 1 }, allow_blank: false
		validates :discount_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }, allow_blank: false


		def tags_csv
			self.tags.join(',')
		end

		def tags_csv=(tags_csv)
			self.tags = tags_csv.split(/,\s*/)
		end

	end
end
