module SwellEcom

	class YourSubscriptionsController < YourController

		def index
			set_page_meta( title: "My Subscriptions" )
			@subscriptions = SwellEcom::Subscription.where( user: current_user ).order( next_charged_at: :desc ).page(params[:page]).per(5)
		end

		def show
			@subscription = SwellEcom::Subscription.where( user: current_user ).find_by( code: params[:id] )
			raise ActionController::RoutingError.new( 'Not Found' ) unless @subscription.present?
			set_page_meta( title: "Subscription \# #{@subscription.code}" )
		end

	end

end
