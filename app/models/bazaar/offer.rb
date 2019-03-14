module Bazaar
	class Offer < ApplicationRecord
		before_save :set_trashed_at
		before_save :set_default_code

		has_many :offer_prices, as: :parent_obj
		has_many :offer_schedules, as: :parent_obj
		has_many :offer_skus, as: :parent_obj

		has_many :wholesale_items

		enum status: { 'draft' => 0, 'active' => 1, 'archive' => 2, 'trash' => 3 }
		enum availability: { 'backorder' => -1, 'pre_order' => 0, 'open_availability' => 1 }

		def page_event_data
			data = {
				id: self.code || self.id,
				name: self.title,
				price: self.offer_prices.active.for_interval( 1 ).first.try(:price_as_money),
				category: nil,
			}

			data
		end

		def set_default_code
			self.code ||= self.title.parameterize
		end

		def set_trashed_at
			self.trashed_at ||= Time.now if self.trash?
		end

	end
end
