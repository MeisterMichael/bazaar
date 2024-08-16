module Bazaar
	class OrderLog < ApplicationRecord

		belongs_to :item, polymorphic: true, required: false
		belongs_to :order

	end
end
