module BazaarCore
	class HouseCouponDiscount < BazaarCore::CouponDiscount
		include BazaarCore::HouseCouponDiscountSearchable if (BazaarCore::HouseCouponDiscountSearchable rescue nil)

	end
end
