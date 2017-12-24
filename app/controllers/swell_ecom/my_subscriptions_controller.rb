module SwellEcom

	class MySubscriptionsController < MyController

		def index
			@subscriptions = SwellEcom::Subscription.where( user: current_user ).order( next_charged_at: :desc ).page(params[:page]).per(5)
		end

		def show
			@subscription = SwellEcom::Subscription.where( user: current_user ).find_by( code: params[:id] )
			raise ActionController::RoutingError.new( 'Not Found' ) unless @subscription.present?
		end

	end

end
