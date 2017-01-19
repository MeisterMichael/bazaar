module SwellEcom
	class Subscription < ActiveRecord::Base
		self.table_name = 'subscriptions'

		belongs_to :plan
		belongs_to :user


	end
end
