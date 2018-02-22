module SwellEcom

	class YourController < ApplicationController
		include SwellEcom::Concerns::EcomConcern

		helper_method :get_billing_countries
		helper_method :get_shipping_countries
		helper_method :get_billing_states
		helper_method :get_shipping_states

		before_action :authenticate_user!
		layout 'swell_ecom/your'

		def index
		end
	end

end
