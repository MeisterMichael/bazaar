module Bazaar
	class CouponDiscount < Bazaar::Discount
		validates :code, uniqueness: { case_sensitive: false }, allow_blank: false, if: :code_present?
	end
end
