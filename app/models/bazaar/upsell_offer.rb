module Bazaar
	class UpsellOffer < ApplicationRecord

		belongs_to :src_product, class_name: 'Bazaar::Product', required: false
		belongs_to :full_price_offer, class_name: 'Bazaar::Offer', required: false
		belongs_to :src_offer, class_name: 'Bazaar::Offer', required: false
		belongs_to :offer

		enum upsell_type: { 'post_sale' => 1, 'at_checkout' => 2 } #, 'post_add_to_cart' => 3 }
		enum status: { 'trash' => -1, 'draft' => 0, 'active' => 1, 'archived' => 2 }

		def product
			self.offer.product
		end

	end
end
