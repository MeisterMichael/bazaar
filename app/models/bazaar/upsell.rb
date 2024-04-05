module Bazaar
	class Upsell < ApplicationRecord

		belongs_to :full_price_offer, class_name: 'Bazaar::Offer', required: false
		belongs_to :offer

		enum upsell_type: { 'post_sale' => 1, 'at_checkout' => 2, 'exit_checkout' => 3 } #, 'post_add_to_cart' => 3 }
		enum status: { 'trash' => -1, 'draft' => 0, 'active' => 1, 'archived' => 2 }

		def product
			self.offer.product
		end

		def to_s
			"#{self.title} (#{self.offer.try(:code)}) #{self.savings}"
		end

	end
end
