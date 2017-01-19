module SwellEcom
	class Subscription < ActiveRecord::Base
		self.table_name = 'subscriptions'

		self.belongs_to :user
		self.belongs_to :plan

	end
end
