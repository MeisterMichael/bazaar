module Bazaar
	class CouponDiscount < Bazaar::Discount
		include Bazaar::CouponDiscountSearchable if (Bazaar::CouponDiscountSearchable rescue nil)

		validates :code, uniqueness: { case_sensitive: false }, allow_blank: false, if: :code_present?
	end
end
