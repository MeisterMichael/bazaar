module BazaarCore
	class OrderSku < ApplicationRecord
		include BazaarCore::Concerns::MoneyAttributesConcern

		belongs_to :sku
		belongs_to :order

	end
end
