module Bazaar
	class WholesaleItem < ApplicationRecord

		include Bazaar::Concerns::MoneyAttributesConcern
		include SwellId::Concerns::PolymorphicIdentifiers

		belongs_to :wholesale_profile
		belongs_to :offer, required: true

		def title
			self.offer.title
		end

	end
end
