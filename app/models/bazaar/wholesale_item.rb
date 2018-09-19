module Bazaar
	class WholesaleItem < ApplicationRecord
		self.table_name = 'wholesale_items'
		include Bazaar::Concerns::MoneyAttributesConcern
		include SwellId::Concerns::PolymorphicIdentifiers

		belongs_to :wholesale_profile
		belongs_to :item, polymorphic: true

		money_attributes :price

	end
end
