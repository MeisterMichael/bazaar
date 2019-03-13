module Bazaar
	class Offer < ApplicationRecord
		before_save :set_trashed_at

		has_many :offer_prices, as: :parent_obj
		has_many :offer_schedules, as: :parent_obj
		has_many :offer_skus, as: :parent_obj

		has_many :wholesale_items

		enum status: { 'draft' => 0, 'active' => 1, 'archive' => 2, 'trash' => 3 }
		enum availability: { 'backorder' => -1, 'pre_order' => 0, 'open_availability' => 1 }

		def set_trashed_at
			self.trashed_at ||= Time.now if self.trash?
		end

	end
end
