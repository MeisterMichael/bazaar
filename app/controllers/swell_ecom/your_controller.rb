module SwellEcom

	class YourController < ApplicationController
		before_action :authenticate_user!
		layout 'swell_ecom/your'

		def index
		end
	end

end
