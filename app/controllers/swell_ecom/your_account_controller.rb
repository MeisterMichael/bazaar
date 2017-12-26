module SwellEcom

	class YourAccountController < YourController

		def index
			@orders = SwellEcom::Order.where( user: current_user ).order( created_at: :desc )
			@subscriptions = SwellEcom::Subscription.where( user: current_user ).order( next_charged_at: :desc )
			set_page_meta( title: "Your Account" )
		end

	end

end
