module Bazaar
	class WholesaleItem < ApplicationRecord

		include Bazaar::Concerns::MoneyAttributesConcern
		include SwellId::Concerns::PolymorphicIdentifiers

		before_save :update_offer
		after_create :update_schedule!
		after_create :update_prices!
		after_create :update_skus!
		before_update :update_price_on_change

		belongs_to :wholesale_profile
		belongs_to :item, polymorphic: true
		belongs_to :offer, required: false
		belongs_to :sku, required: false

		money_attributes :price

		def title
			self.offer.title
		end

		def update_offer
			self.offer ||= Bazaar::Offer.new
			self.offer.status = self.wholesale_profile.status

			if self.item

				self.offer.title						= "#{self.item.title}, Min Quantity #{self.min_quantity}, Wholesale Profile #{self.wholesale_profile.title}"
				self.offer.availability			= self.item.availability
				self.offer.avatar						= self.item.avatar
				self.offer.tax_code					= self.item.tax_code
				self.offer.description			= self.item.description
				self.offer.cart_description	= self.item.cart_description
				self.offer.product					= self.item if self.item.is_a? Bazaar::Product

			end
		end

		def update_offer!
			update_offer
			self.save
			self.offer.save
		end

		def update_price_on_change
			update_prices! if self.price_changed?
		end

		def update_schedule!
			self.offer.offer_schedules.each do |offer_schedule|
				offer_schedule.status = 'trash'
				offer_schedule.save!
			end

			self.offer.offer_schedules.create!( start_interval: 1, max_intervals: 1, interval_value: 0, status: 'active' )
		end

		def update_prices!
			self.offer.offer_prices.each do |offer_price|
				offer_price.status = 'trash'
				offer_price.save!
			end

			self.offer.offer_prices.create!( start_interval: 1, price: self.price, status: 'active' )
		end

		def update_skus!

			self.offer.offer_skus.each do |offer_sku|
				offer_sku.status = 'trash'
				offer_sku.save!
			end

			self.offer.offer_skus.create!( apply: 'per_quantity', sku: self.sku, status: 'active', start_interval: 1, max_intervals:1 ) if self.sku.present?
		end

	end
end
