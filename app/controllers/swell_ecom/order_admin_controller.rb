module SwellEcom
	class OrderAdminController < SwellMedia::AdminController

		before_filter :get_order, except: [ :index ]
		
		def index
			sort_by = params[:sort_by] || 'publish_at'
			sort_dir = params[:sort_dir] || 'desc'

			@orders = Order.order( "#{sort_by} #{sort_dir}" )

			if params[:status].present? && params[:status] != 'all'
				@orders = eval "@orders.#{params[:status]}"
			end

			if params[:q].present?
				@orders = @orders.where( "email like :q", q: "'%#{params[:q].downcase}%'" )
			end

			@orders = @orders.page( params[:page] )
		end

		
		def update
			
		end

		private
			def order_params
				params.require( :order ).permit( :email, :status )
			end

			def get_order
				@order = Order.find_by( id: params[:id] )
			end

	end
end