module Bazaar
	class DiscountUser < ApplicationRecord
		

		belongs_to :discount
		belongs_to :user

	end
end
