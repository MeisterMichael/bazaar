module Bazaar
	class UpsellOffer < ApplicationRecord

		belongs_to :src_product, class_name: 'Bazaar::Product', required: false
		belongs_to :full_price_offer, class_name: 'Bazaar::Offer', required: false
		belongs_to :src_offer, class_name: 'Bazaar::Offer', required: false
		belongs_to :offer

		enum upsell_type: { 'post_sale' => 1, 'at_checkout' => 2 } #, 'post_add_to_cart' => 3 }

		def product
			self.offer.product
		end

		def self.for_source( options={} )
			if options[:product] && options[:offer]
				self.where( src_product: options[:product] ).or( self.where( src_offer: options[:offer] ) )
			elsif options[:offer]
				self.where( src_offer: options[:offer] )
			elsif options[:product]
				self.where( src_product: options[:product] )
			else
				raise Exception.new('Must provide offer and/or product')
			end
		end

	end
end
