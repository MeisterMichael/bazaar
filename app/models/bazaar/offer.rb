module Bazaar
	class Offer < ApplicationRecord
		include SwellId::Concerns::PolymorphicIdentifiers
		include Bazaar::Concerns::MoneyAttributesConcern
		include Bazaar::OfferSearchable if (Bazaar::OfferSearchable rescue nil)

		before_save :set_trashed_at
		before_save :set_default_code

		belongs_to :product

		has_many :offer_prices, as: :parent_obj
		has_many :offer_schedules, as: :parent_obj
		has_many :offer_skus, as: :parent_obj
		has_many :skus, through: :offer_skus

		has_many :order_offers

		has_many :wholesale_items

		has_one_attached :avatar_attachment


		enum status: { 'draft' => 0, 'active' => 1, 'archive' => 2, 'trash' => 3 }
		enum availability: { 'backorder' => -1, 'pre_order' => 0, 'open_availability' => 1 }


		accepts_nested_attributes_for :offer_prices, :offer_schedules, :offer_skus

		money_attributes :initial_price, :suggested_price

		acts_as_taggable_array_on :tags

		before_save		:set_avatar


		def initial_price
			price_for_interval( 1 )
		end

		def price_for_interval( interval = 1, args = {} )
			args[:attribute] ||= :price
			self.offer_prices.active.for_interval( interval ).order( start_interval: :desc, id: :asc ).first.try(args[:attribute])
		end

		def price_as_money_for_interval( interval = 1 )
			self.price_for_interval( interval, attribute: :price_for_money )
		end

		def price_formatted_for_interval( interval = 1 )
			self.price_for_interval( interval, attribute: :price_formatted )
		end

		def interval_period_for_interval( interval = 1 )
			self.offer_schedules.active.for_interval( interval ).order( start_interval: :desc, id: :asc ).limit(1).collect(&:interval_period).first
		end

		def interval_value_for_interval( interval = 1 )
			self.offer_schedules.active.for_interval( interval ).order( start_interval: :desc, id: :asc ).limit(1).collect(&:interval_value).first
		end

		def interval_unit_for_interval( interval = 1 )
			self.offer_schedules.active.for_interval( interval ).order( start_interval: :desc, id: :asc ).limit(1).collect(&:interval_unit).first
		end

		def skus_for_interval( interval = 1 )
			self.skus.merge( self.offer_skus.active.for_interval( interval ) ).order( start_interval: :desc, id: :asc )
		end

		def page_event_data
			data = {
				id: self.code || self.id,
				name: self.cart_title,
				price: self.initial_price_as_money,
				category: nil,
			}

			data
		end

		def product_title
			product.title
		end

		def product_url
			product.url
		end

		def self.zero_price_sum
			self.where( id: Bazaar::OfferPrice.active.where( parent_obj: Bazaar::Offer.all ).group(:parent_obj_type,:parent_obj_id).having("SUM(price) = 0").select(:parent_obj_id) )
		end

		def zero_price_sum?
			self.offer_prices.active.sum(:price) == 0
		end

		def self.not_recurring
			self.where( id: Bazaar::OfferSchedule.active.where( parent_obj: Bazaar::Offer.all ).group(:parent_obj_type,:parent_obj_id).having("SUM(COALESCE(max_intervals,99)) <= 1").select(:parent_obj_id) )
		end

		def not_recurring?
			not( self.recurring? )
		end

		def self.recurring
			self.where( id: Bazaar::OfferSchedule.active.where( parent_obj: Bazaar::Offer.all ).group(:parent_obj_type,:parent_obj_id).having("SUM(COALESCE(max_intervals,99)) > 1").select(:parent_obj_id) )
		end

		def recurring?
			self.offer_schedules.active.sum('COALESCE(max_intervals,99)') > 1
		end

		def set_default_code
			self.code ||= self.title.parameterize
		end

		def set_trashed_at
			self.trashed_at ||= Time.now if self.trash?
		end

		def tags_csv
			self.tags.join(',')
		end

		def tags_csv=(tags_csv)
			self.tags = tags_csv.split(/,\s*/)
		end

		def title_with_price
			"#{self.title} ( #{self.offer_prices.active.order(start_interval: :asc).collect{|op| op.price_formatted}.join(' / ')} )"
		end

		def to_s
			title
		end

		protected
			def set_avatar
				self.avatar = self.avatar_attachment.url if self.avatar_attachment.attached?
			end

	end
end
