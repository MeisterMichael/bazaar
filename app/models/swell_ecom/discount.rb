module SwellEcom
	class Discount < ActiveRecord::Base
		self.table_name = 'discounts'
		include SwellEcom::Concerns::MoneyAttributesConcern

		enum status: { 'archived' => -1, 'draft' => 0, 'active' => 1 }
		enum availability: { 'anyone' => 1, 'selected_users' => 2 }

		has_many :discount_items
		has_many :discount_users

		money_attributes :minimum_prod_subtotal, :minimum_tax_subtotal, :minimum_shipping_subtotal

		def first_discount_item
			@first_discount_item ||= self.discount_items.first
			@first_discount_item
		end

		def first_discount_item=(discount_item)
		end

		def first_discount_item_attributes=( attrs )
			first_discount_item.attributes = attrs
		end

		def in_progress?( args = {} )
			args[:now] ||= Time.now

			( start_at.nil? || args[:now] > start_at ) && ( end_at.nil? || args[:now] < end_at )
		end

		def self.in_progress( args = {} )

			args[:now] ||= Time.now

			self.where('( start_at IS NULL OR :now > start_at ) AND ( end_at IS NULL OR :now < end_at )', now: args[:now] )

		end

	end
end
