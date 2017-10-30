module SwellEcom
	class Subscription < ActiveRecord::Base

		self.table_name = 'subscriptions'

		belongs_to :user
		belongs_to :subscription_plan

	end
end
