module Bazaar
	class OfferSku < ApplicationRecord
		before_save :set_trashed_at

		belongs_to :parent_obj, polymorphic: true
		belongs_to :sku

		enum status: { 'trash' => -1, 'active' => 1 }

		def set_trashed_at
			self.trashed_at ||= Time.now if self.trash?
		end

	end
end
