module SwellEcom

	class YourOrdersController < YourController

		def index
			set_page_meta( title: "My Orders" )
			@orders = SwellEcom::Order.where( user: current_user ).order( created_at: :desc ).page(params[:page]).per(5)
		end

		def show
			@order = SwellEcom::Order.where( user: current_user ).find_by( code: params[:id] )
			raise ActionController::RoutingError.new( 'Not Found' ) unless @order.present?
			set_page_meta( title: "Order Details \##{@order.code}" )
		end

	end

end
