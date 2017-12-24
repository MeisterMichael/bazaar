module SwellEcom

	class MyController < ApplicationController
		before_filter :authenticate_user!

		def index
			@orders = SwellEcom::Order.where( user: current_user ).order( created_at: :desc )
			@subscriptions = SwellEcom::Subscription.where( user: current_user ).order( next_charged_at: :desc )
		end
	end

end
