module SwellEcom
	class DiscountUse < ActiveRecord::Base
		self.table_name = 'discount_users'

		belongs_to :discount
		belongs_to :order
		belongs_to :user

	end
end
