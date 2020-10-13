module BazaarCore
	class CouponDiscount < BazaarCore::Discount
		include BazaarCore::CouponDiscountSearchable if (BazaarCore::CouponDiscountSearchable rescue nil)

		validates :code, uniqueness: { case_sensitive: false }, allow_blank: false, if: :code_present?
	end
end
