module Bazaar
	class Subscription < ApplicationRecord
		include Bazaar::Concerns::UserAddressAttributesConcern
		include Bazaar::Concerns::MoneyAttributesConcern
		include Bazaar::SubscriptionSearchable if (Bazaar::SubscriptionSearchable rescue nil)

		enum status: { 'trash' => -99, 'rejected' => -5, 'on_hold' => -2, 'canceled' => -1, 'failed' => 0, 'active' => 1, 'review' => 98, 'hold_review' => 110 }

		belongs_to	:user, required: false
		belongs_to	:discount, required: false
		belongs_to	:shipping_carrier_service, required: false
		belongs_to	:offer

		belongs_to 	:billing_address, class_name: 'GeoAddress'
		belongs_to 	:shipping_address, class_name: 'GeoAddress'
		belongs_to 	:billing_user_address, class_name: 'UserAddress', required: false #
		belongs_to 	:shipping_user_address, class_name: 'UserAddress', required: false #
		belongs_to	:transaction_provider, required: false
		belongs_to	:merchant_identification, required: false

		has_many :offer_prices, as: :parent_obj
		has_many :offer_schedules, as: :parent_obj

		has_many :subscription_logs
		has_many :subscription_offers
		has_many :offers, through: :subscription_offers

		has_many		:order_offers
		has_many		:orders, through: :order_offers

		before_create :generate_subscription_code
		before_create :initialize_timestamps
		before_save :update_timestamps

		accepts_nested_attributes_for :billing_address, :shipping_address, :user
		accepts_nested_user_address_attributes_for [:billing_user_address,:billing_address,:user_id], [:shipping_user_address,:shipping_address,:user_id]

		money_attributes :amount, :price

		validates	:user, presence: true, allow_blank: false, unless: :trash?
		validates	:amount, presence: true, allow_blank: false, unless: :trash?
		validates	:price, presence: true, allow_blank: false, unless: :trash?
		validates_numericality_of :quantity, greater_than_or_equal_to: 1, unless: :trash?
		validates_numericality_of :amount, greater_than_or_equal_to: 0, unless: :trash?
		validates_numericality_of :price, greater_than_or_equal_to: 0, unless: :trash?

		validates	:billing_interval_value, presence: true, allow_blank: false, unless: :trash?
		validates_numericality_of :billing_interval_value, greater_than_or_equal_to: 1, unless: :trash?
		validates	:billing_interval_unit, presence: true, allow_blank: false, unless: :trash?
		validates_inclusion_of :billing_interval_unit, :in => %w(month months day days week weeks year years), :allow_nil => false, message: '%{value} is not a valid unit of time.', unless: :trash?

		def avatar
			self.offer.avatar
		end

		def billing_interval
			self.billing_interval_value.try(self.billing_interval_unit)
		end

		def self.ready_for_next_charge( time_now = nil )
			time_now ||= Time.now
			active.where( 'next_charged_at < :now', now: time_now )
		end

		def price_for_interval( interval = 1, args = {} )
			args[:attribute] ||= :price

			if ( offer_price = self.offer_prices.active.for_interval( interval ).order( start_interval: :desc, id: :asc ).first ).present?
				offer_price.try(args[:attribute])
			else
				self.offer.price_for_interval( interval, args )
			end
		end

		def price_as_money_for_interval( interval = 1 )
			self.price_for_interval( interval, attribute: :price_as_money )
		end

		def price_formatted_for_interval( interval = 1 )
			self.price_for_interval( interval, attribute: :price_formatted )
		end

		def interval_period_for_interval( interval = 1 )
			if ( offer_schedule = self.offer_schedules.active.for_interval( interval ).order( start_interval: :desc, id: :asc ).first ).present?
				offer_schedule.interval_period
			else
				self.offer.interval_period_for_interval( interval )
			end
		end

		def interval_value_for_interval( interval = 1 )
			if ( offer_schedule = self.offer_schedules.active.for_interval( interval ).order( start_interval: :desc, id: :asc ).first ).present?
				offer_schedule.interval_value
			else
				self.offer.interval_value_for_interval( interval )
			end
		end

		def interval_unit_for_interval( interval = 1 )
			if ( offer_schedule = self.offer_schedules.active.for_interval( interval ).order( start_interval: :desc, id: :asc ).first ).present?
				offer_schedule.interval_unit
			else
				self.offer.interval_unit_for_interval( interval )
			end
		end

		def skus_for_interval( interval = 1 )
			self.offer.skus_for_interval( interval )
		end


		def next_subscription_interval( args = {} )
			orders = Bazaar::Order.where( status: args[:statuses] ) if args[:statuses]
			orders ||= Bazaar::Order.positive_status

			( Bazaar::OrderOffer.where( subscription: self ).joins(:order).merge( orders ).maximum(:subscription_interval) || 0 ) + 1
		end

		def order
			orders.where('bazaar_order_offers.subscription_interval = 1').first
		end

		def page_event_data
			self.offer.page_event_data
		end

		def product_title
			self.offer.product_title
		end

		def product_url
			self.offer.product_url
		end

		def ready_for_next_charge?( time_now = nil )
			time_now ||= Time.now
			self.active? && self.next_charged_at < time_now
		end

		def related_transactions
			Bazaar::Transaction.where( parent_obj: ( self.orders.to_a + [ self ] ) )
		end

		def title
			offer.title
		end

		def to_s
			"#{self.title} (#{self.code})"
		end

		private

		def generate_subscription_code
			self.code = loop do
				if Bazaar.subscription_code_generator_service_class.present?
					token = Bazaar.subscription_code_generator_service_class.constantize.generate_subscription_code( self )
				else
					token = SecureRandom.urlsafe_base64( 6 ).downcase.gsub(/_/,'-')
					token = "#{Bazaar.subscription_code_prefix}#{token}"if Bazaar.subscription_code_prefix.present?
					token = "#{token}#{Bazaar.subscription_code_postfix}"if Bazaar.subscription_code_postfix.present?
				end
				break token unless Subscription.exists?( code: token )
			end
		end

		def initialize_timestamps
			# Fill in any timestamp blanks

			if self.offer.present?

				self.start_at ||= self.created_at
				self.current_period_start_at ||= self.start_at
				self.current_period_end_at ||= self.current_period_start_at + self.billing_interval_value.try( self.billing_interval_unit ) if self.billing_interval_value && self.billing_interval_unit
				self.next_charged_at ||= self.current_period_end_at

			end
		end

		def update_timestamps
			self.canceled_at = Time.now if not( self.canceled_at_changed? ) && self.status_changed? && self.canceled?
		end

	end
end
