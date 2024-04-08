module Bazaar
	class Upsell < ApplicationRecord

		has_one_attached :image_attachment

		belongs_to :full_price_offer, class_name: 'Bazaar::Offer', required: false
		belongs_to :offer

		enum upsell_type: { 'post_sale' => 1, 'at_checkout' => 2, 'exit_checkout' => 3 } #, 'post_add_to_cart' => 3 }
		enum status: { 'trash' => -1, 'draft' => 0, 'active' => 1, 'archived' => 2 }

		acts_as_taggable_array_on :tags

		before_save :set_image_url

		def product
			self.offer.product
		end

		def tags_csv
			self.tags.join(',')
		end

		def tags_csv=(tags_csv)
			self.tags = tags_csv.split(/,\s*/)
		end

		def to_s
			self.internal_title.presence || "#{self.title} (Offer: #{self.offer.try(:code)}#{self.savings.present? ? " / Savings: #{self.savings}" : ""}#{self.upsell_type.present? ? " / Type: #{self.upsell_type.humanize.titleize}" : ""})"
		end

		protected

		def set_image_url
			self.image_url = self.image_attachment.url if self.image_attachment.attached?
		end

	end
end
