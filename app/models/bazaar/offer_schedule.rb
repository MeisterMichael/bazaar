module Bazaar
	class OfferSchedule < ApplicationRecord
		before_save :set_trashed_at

		belongs_to :parent_obj, polymorphic: true

		enum status: { 'trash' => -1, 'active' => 1 }

		validate :validate_start_interval_uniq

		def end_interval
			n = self.class.base_class.where( parent_obj: self.parent_obj ).where('start_interval > ?',self.start_interval).active.order( start_interval: :asc ).first
			if n.present?
				n.start_interval - 1
			else
				self.max_intervals
			end
		end

		def set_trashed_at
			self.trashed_at ||= Time.now if self.trash?
		end

		def validate_start_interval_uniq
			self.errors.add( :start_interval, "start interval must not be unique") if self.class.base_class.where( parent_obj: self.parent_obj, start_interval: self.start_interval ).where.not( id: self.id ).active.present?
		end

	end
end
