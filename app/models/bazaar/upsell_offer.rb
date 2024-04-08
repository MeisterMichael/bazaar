module Bazaar
	class UpsellOffer < ApplicationRecord

		belongs_to :upsell, class_name: 'Bazaar::Upsell'
		belongs_to :src_product, class_name: 'Bazaar::Product', required: false
		# belongs_to :full_price_offer, class_name: 'Bazaar::Offer', through: :upsell
		has_one :full_price_offer, through: :upsell
		belongs_to :src_offer, class_name: 'Bazaar::Offer', required: false
		# belongs_to :offer, required: false
		has_one :offer, through: :upsell


		enum upsell_type: { 'post_sale' => 1, 'at_checkout' => 2, 'exit_checkout' => 3 } #, 'post_add_to_cart' => 3 }
		enum status: { 'trash' => -1, 'draft' => 0, 'active' => 1, 'archived' => 2 }

		# def offer
		# 	self.upsell.try(:offer) || Bazaar::Offer.where(id: self.attributes[:offer_id]).first
		# end

		# def full_price_offer
		# 	self.upsell.try(:full_price_offer) || Bazaar::Offer.where(id: self.attributes[:full_price_offer_id]).first
		# end

		# def upsell_type
		# 	self.upsell.try(:upsell_type) || self.attributes[:upsell_type]
		# end

		def title
			self.upsell.try(:title) || self.attributes[:title]
		end

		def description
			self.upsell.try(:description) || self.attributes[:description]
		end

		def savings
			self.upsell.try(:savings) || self.attributes[:savings]
		end

		def full_price
			self.upsell.try(:full_price) || self.attributes[:full_price]
		end

		def image_url
			self.upsell.try(:image_url) || self.attributes[:image_url]
		end

		def disclaimer
			self.upsell.try(:disclaimer) || self.attributes[:disclaimer]
		end

		def supplemental_disclaimer
			self.upsell.try(:supplemental_disclaimer) || self.attributes[:supplemental_disclaimer]
		end

	end
end
