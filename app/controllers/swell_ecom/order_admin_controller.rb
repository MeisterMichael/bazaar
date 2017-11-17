module SwellEcom
	class OrderAdminController < SwellMedia::AdminController

		before_filter :get_order, except: [ :index ]

		def edit
			@transactions = Transaction.where( parent_obj: @order )
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

		def refund
			refund_amount = ( params[:amount].to_f * 100 ).to_i

			# check that refund amount doesn't exceed charges?
			# amount_net = Transaction.approved.positive.where( parent: @order ).sum(:amount) - Transaction.approved.negative.where( parent: @order ).sum(:amount)

			@transaction_service = SwellEcom.transaction_service_class.constantize.new( SwellEcom.transaction_service_config )

			@transaction = @transaction_service.refund( amount: refund_amount, parent: @order )

			if @transaction.errors.present?

				set_flash @transaction.errors.full_messages, :danger

			else

				OrderMailer.refund( @transaction ).deliver_now
				set_flash "Refund successful", :success

			end

			redirect_to swell_ecom.edit_order_admin_path( @order )
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
