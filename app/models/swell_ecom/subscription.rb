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

		def trial?
			# @todo implement logic to determine if subscription is currently a trial
			current_interval = nil
			self.subscription_plan.trial? && current_interval <= self.subscription_plan.trial_max_intervals
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
