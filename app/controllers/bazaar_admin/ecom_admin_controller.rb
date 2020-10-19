
module BazaarAdmin
	class EcomAdminController < ApplicationAdminController
		include Bazaar::Concerns::EcomConcern

		helper_method :get_billing_countries
		helper_method :get_shipping_countries
		helper_method :get_billing_states
		helper_method :get_shipping_states



	end
end
