module Bazaar
	class PromotionDiscount < Bazaar::Discount
		include Bazaar::PromotionDiscountSearchable if (Bazaar::PromotionDiscountSearchable rescue nil)

	end
end
