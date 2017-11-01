module SwellEcom
	class Subscription < ActiveRecord::Base

		self.table_name = 'subscriptions'

		enum status: { 'canceled' => -1, 'active' => 1 }

		belongs_to :user
		belongs_to :subscription_plan
		belongs_to :order_item # the order item which generated the subscription

		before_create :generate_order_code

		private

		def generate_order_code
			self.code = loop do
  				token = SecureRandom.urlsafe_base64( 6 )
  				break token unless Subscription.exists?( code: token )
			end
		end
	end
end
