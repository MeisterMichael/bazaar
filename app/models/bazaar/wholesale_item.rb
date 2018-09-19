module Bazaar
	class WholesaleItem < ApplicationRecord

		include Bazaar::Concerns::MoneyAttributesConcern
		include SwellId::Concerns::PolymorphicIdentifiers

		belongs_to :wholesale_profile
		belongs_to :item, polymorphic: true

		money_attributes :price

	end
end
