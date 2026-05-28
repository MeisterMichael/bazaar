module Bazaar
	class Subscription < ApplicationRecord
		include Bazaar::Concerns::UserAddressAttributesConcern
		include Bazaar::Concerns::MoneyAttributesConcern
		include Bazaar::SubscriptionSearchable if (Bazaar::SubscriptionSearchable rescue nil)

		enum status: { 'trash' => -99, 'rejected' => -5, 'on_hold' => -2, 'canceled' => -1, 'failed' => 0, 'active' => 1, 'review' => 98, 'hold_review' => 110 }

		enum failed_reason: {
			'transient_retrying'             => 1,
			'user_action_required'           => 10,
			'payment_method_invalidated'     => 20,
			'provider_authorization_revoked' => 30,
			'card_flagged'                   => 40,
			'retries_exhausted'              => 90,
			'unknown_reason'                 => 99,
		}, _prefix: :failed_reason

		enum failed_recovery_action: {
			'none_required'           => 0,
			'update_credit_card'      => 1,
			'verify_billing_address'  => 2,
			'verify_security_code'    => 3,
			'reauthorize_provider'    => 4,
			'contact_support'         => 8,
			'terminal_no_action'      => 9,
		}, _prefix: :recovery_action

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
		# has_many :subscription_periods

		has_many		:order_offers
		has_many		:orders, through: :order_offers

		# Properties hash keys set when a customer pauses their subscription
		# (see Settings::SubscriptionsController#pause in nhc-web). These keys
		# are cleared by the clear_stale_pause_metadata callback when the sub
		# transitions to a terminal/broken status OR when the pause's natural
		# end date has passed — leaving them lying around makes the
		# subscription_paused? helper return stale truthy values and produces
		# "PAUSED and canceled at the same time" UI anomalies.
		PAUSE_PROPERTY_KEYS = %w[
			paused_at
			paused_until
			pre_pause_next_charged_at
			pause_duration_months
		].freeze

		# Statuses where pause metadata is no longer meaningful. active, review,
		# and hold_review preserve pause metadata so that a sub temporarily moved
		# to admin review doesn't lose the customer's pause intent.
		CLEAR_PAUSE_METADATA_STATUSES = %w[trash rejected on_hold canceled failed].freeze

		before_create :generate_subscription_code
		before_create :initialize_timestamps
		before_save :update_timestamps
		before_save :clear_stale_pause_metadata

		accepts_nested_attributes_for :billing_address, :shipping_address, :user
		accepts_nested_user_address_attributes_for [:billing_user_address,:billing_address,:user_id], [:shipping_user_address,:shipping_address,:user_id]

		money_attributes :amount, :price, :estimated_tax, :estimated_shipping, :estimated_discount, :estimated_subtotal, :estimated_total

		acts_as_taggable_array_on :tags

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

		# Removes the pause metadata keys (PAUSE_PROPERTY_KEYS) from the
		# properties hash when either:
		#   - the subscription is moving to a terminal/broken status (see
		#     CLEAR_PAUSE_METADATA_STATUSES — these are the statuses where a
		#     pause no longer makes sense), or
		#   - the pause's natural end date (paused_until) has already passed.
		#
		# Active, review, and hold_review subs with a future paused_until are
		# preserved — that's the legitimate "currently paused" state.
		#
		# The audit trail (when the sub was paused, for how long, etc.) is
		# preserved separately in bazaar_subscription_logs and Bunyan events,
		# so deleting these properties does not lose history.
		def clear_stale_pause_metadata
			return unless self.properties.is_a?(Hash)
			return unless self.properties.key?('paused_until')

			pause_expired = begin
				Time.parse( self.properties['paused_until'].to_s ) <= Time.now
			rescue ArgumentError, TypeError
				true  # malformed value → treat as expired
			end

			return unless CLEAR_PAUSE_METADATA_STATUSES.include?( self.status ) || pause_expired

			PAUSE_PROPERTY_KEYS.each { |key| self.properties.delete(key) }
		end

	end
end
