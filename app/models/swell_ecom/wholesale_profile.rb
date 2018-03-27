module SwellEcom
	class WholesaleProfile < ApplicationRecord
		self.table_name = 'wholesale_profiles'

		has_many :wholesale_items

		enum status: { 'trash' => -1, 'draft' => 0, 'active' => 1, 'archived' => 2 }

		accepts_nested_attributes_for :wholesale_items

	end
end
