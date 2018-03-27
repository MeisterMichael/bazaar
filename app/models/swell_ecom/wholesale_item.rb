module SwellEcom
	class WholesaleItem < ApplicationRecord
		self.table_name = 'wholesale_items'
		include SwellEcom::Concerns::MoneyAttributesConcern

		belongs_to :wholesale_profile
		belongs_to :item, polymorphic: true

		money_attributes :price

	end
end
