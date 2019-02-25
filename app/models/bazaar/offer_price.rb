module Bazaar
	class OfferPrice < ApplicationRecord
		before_save :set_trashed_at

		belongs_to :parent_obj, polymorphic: true

		enum status: { 'trash' => -1, 'active' => 1 }

		validate :validate_start_interval_uniq

		include Bazaar::Concerns::MoneyAttributesConcern
		money_attributes :price

		def end_interval
			n = self.class.base_class.where( parent_obj: self.parent_obj ).where('start_interval > ?',self.start_interval).active.order( start_interval: :asc ).first
			if n.present?
				n.start_interval - 1
			else
				nil
			end
		end

		def self.for_interval( interval )
			self.where( ":interval >= start_interval AND ( max_intervals IS NULL OR :interval <= ( start_interval + max_intervals ) )", interval: interval )
		end

		def set_trashed_at
			self.trashed_at ||= Time.now if self.trash?
		end

		def validate_start_interval_uniq
			with_same_interval = self.class.base_class.where( parent_obj: self.parent_obj, start_interval: self.start_interval ).where.not( id: self.id ).active
			self.errors.add( :start_interval, "start interval must not be unique") if with_same_interval.present?
		end

	end
end
