module SwellEcom

	class MyOrdersController < MyController

		def index
			@orders = SwellEcom::Order.where( user: current_user ).order( created_at: :desc ).page(params[:page]).per(5)
		end

		def show
			@order = SwellEcom::Order.where( user: current_user ).find_by( code: params[:id] )
			raise ActionController::RoutingError.new( 'Not Found' ) unless @order.present?
		end

	end

end
