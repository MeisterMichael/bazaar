module SwellEcom
	class Subscription < ActiveRecord::Base
		self.table_name = 'subscriptions'

		include SwellEcom::Concerns::MoneyAttributesConcern

		enum status: { 'canceled' => -1, 'failed' => 0, 'active' => 1 }
		enum availability: { 'backorder' => -1, 'pre_order' => 0, 'open_availability' => 1 }

		belongs_to :user
		belongs_to :subscription_plan
		belongs_to :discount, required: false

		belongs_to 	:billing_address, class_name: 'GeoAddress'
		belongs_to 	:shipping_address, class_name: 'GeoAddress'

		before_create :generate_order_code
		before_create :initialize_timestamps

		accepts_nested_attributes_for :user
		accepts_nested_attributes_for :billing_address

		money_attributes :amount, :trial_amount

		def self.ready_for_next_charge( time_now = nil )
			time_now ||= Time.now
			active.where( 'next_charged_at < :now', now: time_now )
		end

		def is_next_interval_a_trial?
			return false unless self.subscription_plan.trial?

			if not( self.persisted? )
				return true
			else
				interval_count = SwellEcom::OrderItem.where( item: self ).count + SwellEcom::OrderItem.where( subscription: self ).count
				return interval_count < self.subscription_plan.trial_max_intervals
			end
		end

		def order
			Order.joins(:order_items).where( order_items: { subscription_id: self.id } ).first
		end

		def orders
			Order.where( "orders.id = :order_id OR (orders.parent_type = :subscription_type AND orders.parent_id = :subscription_id)", subscription_id: self.id, subscription_type: SwellEcom::Subscription.base_class.name, order_id: self.order.id )
		end

		def ready_for_next_charge?( time_now = nil )
			time_now ||= Time.now
			self.active? && self.next_charged_at < time_now
		end

		def sku
			subscription_plan.sku
		end

		private

		def generate_order_code
			self.code = loop do
  				token = SecureRandom.urlsafe_base64( 6 ).downcase.gsub(/_/,'-')
				token = "#{SwellEcom.subscription_code_prefix}#{token}"if SwellEcom.order_code_prefix.present?
				token = "#{token}#{SwellEcom.subscription_code_postfix}"if SwellEcom.order_code_postfix.present?
  				break token unless Subscription.exists?( code: token )
			end
		end

		def initialize_timestamps
			# Fill in any timestamp blanks

			if self.subscription_plan.present?

				self.start_at ||= self.created_at
				self.current_period_start_at ||= self.start_at

				trial_interval = self.subscription_plan.trial_interval_value.try( self.subscription_plan.trial_interval_unit )
				billing_interval = self.subscription_plan.billing_interval_value.try( self.subscription_plan.billing_interval_unit )

				if self.subscription_plan.trial?

					self.trial_start_at ||= self.start_at
					self.trial_end_at ||= self.trial_start_at + trial_interval * self.subscription_plan.trial_max_intervals

					self.current_period_end_at ||= self.current_period_start_at + trial_interval
				end
				self.current_period_end_at ||= self.current_period_start_at + billing_interval

				self.next_charged_at ||= self.current_period_end_at

			end
		end
	end
end
