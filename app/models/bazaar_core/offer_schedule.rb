module BazaarCore
	class OfferSchedule < ApplicationRecord
		before_save :set_trashed_at

		belongs_to :parent_obj, polymorphic: true

		enum status: { 'trash' => -1, 'active' => 1 }

		validate :validate_start_interval_uniq

		def self.for_interval( interval )
			self.where( ":interval >= start_interval AND ( max_intervals IS NULL OR :interval < ( start_interval + max_intervals ) )", interval: interval )
		end

		def interval_period
			interval_value.try(interval_unit)
		end

		def end_interval
			n = self.class.base_class.where( parent_obj: self.parent_obj ).where('start_interval > ?',self.start_interval).active.order( start_interval: :asc ).first
			if n.present?
				n.start_interval - 1
			elsif self.max_intervals.present?
				self.start_interval + self.max_intervals - 1
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

		def set_trashed_at
			self.trashed_at ||= Time.now if self.trash?
		end

		def validate_start_interval_uniq
			return if self.trash?
			self.errors.add( :start_interval, "start interval must not be unique") if self.class.base_class.where( parent_obj: self.parent_obj, start_interval: self.start_interval ).where.not( id: self.id ).active.present?
		end

	end
end
