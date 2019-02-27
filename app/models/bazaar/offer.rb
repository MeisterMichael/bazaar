module Bazaar
	class Offer < ApplicationRecord
		before_save :set_trashed_at

		has_many :offer_prices, as: :parent_obj
		has_many :offer_schedules, as: :parent_obj
		has_many :offer_skus, as: :parent_obj

		enum status: { 'draft' => 0, 'active' => 1, 'archive' => 2, 'trash' => 3 }
		enum availability: { 'backorder' => -1, 'pre_order' => 0, 'open_availability' => 1 }

		def self.not_recurring
			where.not( id: Bazaar::OfferSchedule.active.where( parent_obj_type: Bazaar::Offer.base_class.name ).group(:parent_obj_id).having('SUM(coalesce(max_intervals,2)) > 1').select(:parent_obj_id) )
		end

		def self.recurring
			where( id: Bazaar::OfferSchedule.active.where( parent_obj_type: Bazaar::Offer.base_class.name ).group(:parent_obj_id).having('SUM(coalesce(max_intervals,2)) > 1').select(:parent_obj_id) )
		end

		def not_recurring?
			not(self.recurring?)
		end

		def recurring?
			active_offer_schedules = self.offer_schedules.active.order( start_interval: :asc, id: :asc )
			active_offer_schedule = active_offer_schedules.first

			active_offer_schedule.present? && ( active_offer_schedule.max_intervals != 1 || active_offer_schedules.count > 1 )
		end

		def set_trashed_at
			self.trashed_at ||= Time.now if self.trash?
		end

	end
end
