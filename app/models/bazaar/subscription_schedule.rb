module Bazaar
	class SubscriptionSchedule < ApplicationRecord
		before_save :set_trashed_at

		belongs_to :parent_obj, polymorphic: true

		validate :sequence_uniq

		enum status: { 'trash' => -1, 'active' => 1 }


		def set_trashed_at
			self.trashed_at ||= Time.now if self.trash?
		end

		def sequence_uniq
			self.errors.add( :sequence, "sequence must not be unique") if self.class.base_class.where( parent_obj: self.parent_obj, sequence: self.sequence ).where.not( id: self.id ).active.present?
		end

	end
end
