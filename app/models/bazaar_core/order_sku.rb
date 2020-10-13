module Bazaar
	class OrderSku < ApplicationRecord
		include Bazaar::Concerns::MoneyAttributesConcern

		belongs_to :sku
		belongs_to :order

	end
end
