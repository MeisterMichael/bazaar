module SwellEcom
	class Subscription < ActiveRecord::Base


		self.table_name = 'subscriptions'
		self.table_name = 'subscriptions'

		enum status: { 'canceled' => -1, 'failed' => 0, 'active' => 1 }

		belongs_to :user
		belongs_to :subscription_plan

		belongs_to 	:billing_address, class_name: 'GeoAddress'
		belongs_to 	:shipping_address, class_name: 'GeoAddress'

		before_create :generate_order_code

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
  				token = SecureRandom.urlsafe_base64( 6 )
  				break token unless Subscription.exists?( code: token )
			end
		end
	end
end
