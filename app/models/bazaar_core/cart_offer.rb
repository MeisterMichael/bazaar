module BazaarCore
	class CartOffer < ApplicationRecord

		include BazaarCore::Concerns::MoneyAttributesConcern

		belongs_to 	:cart
		belongs_to 	:item, polymorphic: true, required: false
		belongs_to 	:offer, required: false

		money_attributes :subtotal, :price

		delegate :to_s, to: :offer

	end
end
