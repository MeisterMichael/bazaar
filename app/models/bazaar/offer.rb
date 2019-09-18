module Bazaar
	class Offer < ApplicationRecord
		include Bazaar::Concerns::MoneyAttributesConcern

		before_save :set_trashed_at
		before_save :set_default_code

		belongs_to :product

		has_many :offer_prices, as: :parent_obj
		has_many :offer_schedules, as: :parent_obj
		has_many :offer_skus, as: :parent_obj
		has_many :skus, through: :offer_skus

		has_many :wholesale_items

		has_one_attached :avatar_attachment


		enum status: { 'draft' => 0, 'active' => 1, 'archive' => 2, 'trash' => 3 }
		enum availability: { 'backorder' => -1, 'pre_order' => 0, 'open_availability' => 1 }


		accepts_nested_attributes_for :offer_prices, :offer_schedules, :offer_skus

		money_attributes :initial_price

		before_save		:set_avatar


		def initial_price
			price_for_interval( 1 )
		end

		def price_for_interval( interval = 1 )
			self.offer_prices.active.for_interval( interval ).first.try(:price)
		end

		def interval_period_for_interval( interval = 1 )
			self.offer_schedules.active.for_interval( interval ).limit(1).collect(&:interval_period).first
		end

		def interval_value_for_interval( interval = 1 )
			self.offer_schedules.active.for_interval( interval ).limit(1).collect(&:interval_value).first
		end

		def interval_unit_for_interval( interval = 1 )
			self.offer_schedules.active.for_interval( interval ).limit(1).collect(&:interval_unit).first
		end

		def skus_for_interval( interval = 1 )
			self.skus.merge( self.offer_skus.active.for_interval( interval ) )
		end

		def page_event_data
			data = {
				id: self.code || self.id,
				name: self.title,
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

		def is_recurring?
			self.offer_schedules.active.count > 1 || self.offer_schedules.active.sum('COALESCE(max_intervals,99)') > 0
		end

		def set_default_code
			self.code ||= self.title.parameterize
		end

		def set_trashed_at
			self.trashed_at ||= Time.now if self.trash?
		end

		protected
			def set_avatar
				self.avatar = self.avatar_attachment.service_url if self.avatar_attachment.attached?
			end

	end
end
