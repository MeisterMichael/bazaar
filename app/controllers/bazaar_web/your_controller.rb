module BazaarWeb

	class YourController < ApplicationController
		include BazaarCore::Concerns::EcomConcern

		helper_method :get_billing_countries
		helper_method :get_shipping_countries
		helper_method :get_billing_states
		helper_method :get_shipping_states

		before_action :authenticate_user!
		layout 'bazaar_web/your'

		def index
		end
	end

end
