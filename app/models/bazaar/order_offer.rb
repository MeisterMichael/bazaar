module Bazaar
	class OrderOffer < ApplicationRecord
		include Bazaar::Concerns::MoneyAttributesConcern

		belongs_to :offer
		belongs_to :order
		belongs_to :subscription, required: false, validate: true

		money_attributes :subtotal, :price, :tax

	end
end
