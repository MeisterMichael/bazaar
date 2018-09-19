module Bazaar
	class DiscountUser < ApplicationRecord
		self.table_name = 'discount_users'

		belongs_to :discount
		belongs_to :user

	end
end
