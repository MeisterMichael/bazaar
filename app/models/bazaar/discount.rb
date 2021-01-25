module Bazaar
	class Discount < ApplicationRecord

		include Bazaar::Concerns::MoneyAttributesConcern
		include Bazaar::DiscountSearchable if (Bazaar::DiscountSearchable rescue nil)

		before_save :downcase_code

		enum status: { 'archived' => -1, 'draft' => 0, 'active' => 1 }
		enum availability: { 'anyone' => 1, 'selected_users' => 2 }

		has_many :discount_items
		has_many :discount_users
		belongs_to 	:user, required: false, class_name: 'User'

		money_attributes :minimum_prod_subtotal, :minimum_tax_subtotal, :minimum_shipping_subtotal

		accepts_nested_attributes_for :discount_items, allow_destroy: true

		validates :minimum_prod_subtotal, presence: true, numericality: { greater_than_or_equal_to: 0 }, allow_blank: false
		validates :minimum_tax_subtotal, presence: true, numericality: { greater_than_or_equal_to: 0 }, allow_blank: false
		validates :minimum_shipping_subtotal, presence: true, numericality: { greater_than_or_equal_to: 0 }, allow_blank: false
		validates :limit_per_customer, numericality: { greater_than_or_equal_to: 1 }, allow_blank: true
		validates :limit_global, numericality: { greater_than_or_equal_to: 1 }, allow_blank: true


		def self.in_progress( args = {} )

			args[:now] ||= Time.now

			self.where('( start_at IS NULL OR :now > start_at ) AND ( end_at IS NULL OR :now < end_at )', now: args[:now] )

		end



		def amount
			self.discount_items.last.try( :discount_amount )
		end

		def code_present?
			self.code.present?
		end

		def downcase_code
			if self.code.present?
				if self.code.strip.blank?
					self.code = nil
				else
					self.code = self.code.downcase.strip
				end
			end
		end

		def for_subscriptions?
			self.discount_items.where('maximum_orders > 1').present?
		end

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

		def non_recurring_orders?
			self.max_subscription_interval == 1 && self.min_subscription_interval == 1
		end

		def to_s
			self.title.present? ? self.title : self.code
		end

	end
end
