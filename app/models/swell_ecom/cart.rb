module SwellEcom

	class Cart < ActiveRecord::Base
		self.table_name = 'carts'

		has_many :cart_items
		belongs_to :user

	end

end
