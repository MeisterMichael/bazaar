module SwellEcom
	class Discount < ActiveRecord::Base
		self.table_name = 'discounts'

		enum status: { 'archived' => -1, 'draft' => 0, 'active' => 1 }
		enum availability: { 'anyone' => 1, 'selected_users' => 2 }

	end
end
