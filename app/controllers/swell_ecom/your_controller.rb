module SwellEcom

	class YourController < ApplicationController
		before_filter :authenticate_user!
		layout 'swell_ecom/your'

		def index
		end
	end

end
