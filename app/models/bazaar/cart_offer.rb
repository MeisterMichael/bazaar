module Bazaar
	class CartOffer < ApplicationRecord

		include Bazaar::Concerns::MoneyAttributesConcern

		belongs_to 	:cart
		belongs_to 	:item, polymorphic: true, required: false
		belongs_to 	:offer, required: false
		belongs_to :source_obj, required: false, polymorphic: true

		money_attributes :subtotal, :price

		delegate :to_s, to: :offer

	end
end
