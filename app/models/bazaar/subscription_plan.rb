module Bazaar
	class SubscriptionPlan < ApplicationRecord


		include Pulitzer::Concerns::URLConcern
		include Bazaar::Concerns::MoneyAttributesConcern
		include SwellId::Concerns::PolymorphicIdentifiers
		include Bazaar::ProductSearchable if (Bazaar::ProductSearchable rescue nil)

		enum status: { 'draft' => 0, 'active' => 1, 'archive' => 2, 'trash' => 3 }
		enum availability: { 'backorder' => -1, 'pre_order' => 0, 'open_availability' => 1 }
		enum package_shape: { 'no_shape' => 0, 'letter' => 1, 'box' => 2, 'cylinder' => 3 }

		belongs_to 	:item, polymorphic: true, required: false
		belongs_to :offer, required: false
		has_many :offer_prices, through: :offer
		has_many :offer_schedules, through: :offer
		has_many :offer_skus, through: :offer
		has_one_attached :avatar_attachment
		has_many_attached :embedded_attachments
		has_many_attached :gallery_attachments
		has_many_attached :other_attachments

		validates		:title, presence: true, unless: :allow_blank_title?

		validates	:billing_interval_value, presence: true, allow_blank: false
		validates_numericality_of :billing_interval_value, greater_than_or_equal_to: 1
		validates	:billing_interval_unit, presence: true, allow_blank: false
		validates_inclusion_of :billing_interval_unit, :in => %w(month months day days week weeks year years), :allow_nil => false, message: '%{value} is not a valid unit of time.'


		validates	:trial_interval_value, presence: true, allow_blank: false
		validates_numericality_of :trial_interval_value, greater_than_or_equal_to: 1
		validates	:trial_interval_unit, presence: true, allow_blank: false
		validates_inclusion_of :trial_interval_unit, :in => %w(month months day days week weeks year years), :allow_nil => false, message: '%{value} is not a valid unit of time.'

		money_attributes :trial_price, :price, :shipping_price, :purchase_price

		mounted_at '/subscriptions'


		before_save		:set_avatar
		before_save	:set_publish_at
		before_save :save_offer
		before_update :update_schedule_and_price_on_change
		after_create :update_schedule!
		after_create :update_prices!

		attr_accessor	:slug_pref

		include FriendlyId
		friendly_id :slugger, use: [ :slugged, :history ]

		def self.published( args = {} )
			where( "bazaar_subscription_plans.publish_at <= :now", now: Time.zone.now ).active
		end

		def bazaar_uid
			"subscription_plan_#{self.id}"
		end

		def page_event_data
			category_name = self.product_category.name if self.respond_to?(:product_category)

			event_price = self.purchase_price_as_money

			data = {
				id: bazaar_uid,
				name: self.title,
				price: event_price,
				category: category_name,
			}

			data
		end

		def page_meta
			if self.title.present?
				title = "#{self.title} )°( #{Pulitzer.app_name}"
			else
				title = Pulitzer.app_name
			end

			return {
				page_title: title,
				title: self.title,
				description: self.sanitized_description,
				image: self.avatar,
				url: self.url,
				twitter_format: 'summary_large_image',
				type: 'Product',
				og: {
					"article:published_time" => self.publish_at.iso8601,
					"product:price:amount" => self.price / 100.to_f,
					"product:price:currency" => 'USD'
				},
				data: {
					'url' => self.url,
					'name' => self.title,
					'description' => self.sanitized_description,
					'datePublished' => self.publish_at.iso8601,
					'image' => self.avatar
				}

			}
		end

		def product_title
			self.item.product_title
		end

		def product_url
			self.item.product_url
		end

		def published?
			active? && publish_at < Time.zone.now
		end

		def purchase_price
			if self.trial?
				self.trial_price
			else
				self.price
			end
		end

		def sanitized_content
			ActionView::Base.full_sanitizer.sanitize( self.content )
		end

		def sanitized_description
			ActionView::Base.full_sanitizer.sanitize( self.description )
		end

		def slugger
			if self.slug_pref.present?
				self.slug = nil # friendly_id 5.0 only updates slug if slug field is nil
				return self.slug_pref
			else
				return self.title
			end
		end

		def sku
			"sub-#{self.slug}"
		end

		def tags_csv
			self.tags.join(',')
		end

		def tags_csv=(tags_csv)
			self.tags = tags_csv.split(/,\s*/)
		end

		def to_s
			self.title
		end

		def trial?
			self.trial_max_intervals > 0
		end

		def update_offer
			self.offer ||= Bazaar::Offer.new
			self.offer.title						= self.title
			self.offer.status						= self.status
			self.offer.availability			= self.availability
			self.offer.avatar						= self.avatar
			self.offer.tax_code					= self.tax_code
			self.offer.description			= self.description
			self.offer.cart_description	= self.cart_description
			self.offer.product					= self.item if self.item.is_a? Bazaar::Product
		end

		def save_offer
			update_offer
			self.offer.save
		end

		def update_offer!
			update_offer
			self.save
			self.offer.save
		end

		def update_schedule_and_price_on_change
			update_schedule! if self.trial_max_intervals_changed? || self.trial_interval_value_changed? || self.trial_interval_unit_changed? || self.billing_interval_value_changed? || self.billing_interval_unit_changed?
			update_prices! if self.trial_price_changed? || self.price_changed?
		end

		def update_schedule!
			self.offer.offer_schedules.each do |offer_schedule|
				offer_schedule.trash!
			end

			if "#{self.trial_interval_value} #{self.trial_interval_unit.strip}".downcase == "#{self.billing_interval_value} #{self.billing_interval_unit.strip}".downcase
				self.offer.offer_schedules.create!( start_interval: 1, interval_unit: self.billing_interval_unit, interval_value: self.billing_interval_value, status: 'active' )
			else
				self.offer.offer_schedules.create!( start_interval: 1, interval_unit: self.trial_interval_unit, interval_value: self.trial_interval_value, status: 'active' ) if self.trial?
				self.offer.offer_schedules.create!( start_interval: self.trial_max_intervals + 1, interval_unit: self.billing_interval_unit, interval_value: self.billing_interval_value, status: 'active' )
			end

		end

		def update_prices!
			self.offer.offer_prices.each do |offer_price|
				offer_price.trash!
			end

			if self.trial_price == self.price
				self.offer.offer_prices.create!( start_interval: 1, price: self.price, status: 'active' )
			else
				self.offer.offer_prices.create!( start_interval: 1, max_intervals: self.trial_max_intervals, price: self.trial_price, status: 'active' ) if self.trial?
				self.offer.offer_prices.create!( start_interval: self.trial_max_intervals + 1, price: self.price, status: 'active' )
			end
		end


		protected

			def set_avatar
				self.avatar = self.avatar_attachment.service_url if self.avatar_attachment.attached?
			end

		private
			def allow_blank_title?
				self.slug_pref.present?
			end

			def set_publish_at
				# set publish_at
				self.publish_at ||= Time.zone.now
			end

	end
end
