module Bazaar
	class HouseCouponDiscount < Bazaar::CouponDiscount
		include Bazaar::HouseCouponDiscountSearchable if (Bazaar::HouseCouponDiscountSearchable rescue nil)

	end
end
