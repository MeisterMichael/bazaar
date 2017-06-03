module SwellEcom
	class OrderAdminController < SwellMedia::AdminController

		before_filter :get_order, except: [ :index ]
		
		def edit
			
		end

		def index
			sort_by = params[:sort_by] || 'created_at'
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
			@order.attributes = order_params
		
			if @order.status_changed? && ( @order.status == 'fulfilled' && @order.status_was == 'placed' )
				@order.fulfilled_at = Time.zone.now
			end
			@order.save
			redirect_to :back
		end

		private
			def order_params
				params.require( :order ).permit( :email, :status, :support_notes )
			end

			def get_order
				@order = Order.find_by( id: params[:id] )
			end

	end
end