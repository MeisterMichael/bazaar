module BazaarWeb

	class YourAccountController < YourController

		def index
			@orders = Bazaar::Order.where( user: current_user ).order( created_at: :desc )
			@subscriptions = Bazaar::Subscription.where( user: current_user ).order( next_charged_at: :desc )
			set_page_meta( title: "Your Account" )
		end

	end

end
