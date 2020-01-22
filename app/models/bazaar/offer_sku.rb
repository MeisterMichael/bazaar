module Bazaar
	class OfferSku < ApplicationRecord
		before_save :set_trashed_at

		belongs_to :parent_obj, polymorphic: true
		belongs_to :sku

		enum status: { 'trash' => -1, 'active' => 1 }
		enum apply: { 'per_quantity' => 1, 'per_order' => 2 }

		def calculate_quantity( qty )
			if self.per_quantity?
				qty * self.quantity
			else
				self.quantity
			end
		end

		def end_interval
			start_interval + max_intervals - 1
		end

		def self.for_interval( interval )
			self.where( ":interval >= start_interval AND ( max_intervals IS NULL OR :interval < ( start_interval + max_intervals ) )", interval: interval )
		end

		def set_trashed_at
			self.trashed_at ||= Time.now if self.trash?
		end

	end
end
