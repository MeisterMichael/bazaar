module Bazaar
	class OfferSku < ApplicationRecord
		before_save :set_trashed_at

		belongs_to :parent_obj, polymorphic: true
		belongs_to :sku

		enum status: { 'trash' => -1, 'active' => 1 }
		enum apply: { 'per_quantity' => 1, 'per_order' => 2 }

		validates :shipping_exemptions, allow_nil: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: :quantity }, allow_blank: true

		def calculate_quantity( qty )
			if self.per_quantity?
				qty * self.quantity
			else
				self.quantity
			end
		end

		def end_interval
			if max_intervals.present?
				start_interval + max_intervals - 1
			else
				nil
			end
		end

		def end_interval_with_infinity
			end_interval || Float::INFINITY
		end

		def max_intervals_with_infinity
			max_intervals || Float::INFINITY
		end

		def self.for_interval( interval )
			self.where( ":interval >= start_interval AND ( max_intervals IS NULL OR :interval < ( start_interval + max_intervals ) )", interval: interval )
		end

		def set_trashed_at
			self.trashed_at ||= Time.now if self.trash?
		end

	end
end
