module SwellEcom
	class DiscountUser < ActiveRecord::Base
		self.table_name = 'discount_users'

		belongs_to :discount
		belongs_to :user

	end
end
