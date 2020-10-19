module BazaarCore
	class PromotionDiscount < BazaarCore::Discount
		include BazaarCore::PromotionDiscountSearchable if (BazaarCore::PromotionDiscountSearchable rescue nil)

	end
end
