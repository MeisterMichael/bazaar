
module SwellEcom
	class EcomAdminController < ApplicationAdminController
		include SwellEcom::Concerns::EcomConcern

		helper_method :get_billing_countries
		helper_method :get_shipping_countries
		helper_method :get_billing_states
		helper_method :get_shipping_states



	end
end
