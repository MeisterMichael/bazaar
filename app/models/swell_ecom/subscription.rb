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
			if not( self.persisted? ) && self.subscription_plan.trial?
				return true
			else
				interval_count = SwellEcom::OrderItem.where( item: self ).count + 1
				return self.subscription_plan.trial? && interval_count <= self.subscription_plan.trial_max_intervals
			end
		end

		def order
			Order.joins(:order_items).where( order_items: { subscription_id: self.id } ).first
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
