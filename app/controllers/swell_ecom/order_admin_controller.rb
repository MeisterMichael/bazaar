module SwellEcom
	class OrderAdminController < SwellEcom::EcomAdminController


		before_action :get_order, except: [ :index, :bulk_update, :bulk_destroy ]
		before_action :get_orders, except: [ :bulk_update, :bulk_destroy ]
		before_action :init_search_service, only: [:index]

		def address
			authorize( @order, :admin_update? )
			address_attributes = params.require( :geo_address ).permit( :first_name, :last_name, :geo_country_id, :geo_state_id, :street, :street2, :city, :zip, :phone )
			address = GeoAddress.create( address_attributes.merge( user: @order.user ) )

			if address.errors.present?

				set_flash address.errors.full_messages, :danger

			else

				attribute_name = params[:attribute] == 'billing_address' ? 'billing_address' : 'shipping_address'
				# @todo trash the old address if it's no long used by any orders or subscriptions
				@order.update( attribute_name => address )

				set_flash "Address Updated", :success

			end
			redirect_back fallback_location: '/admin'
		end

		def bulk_update
			@orders.each do |order|
				order.attributes = order_params

				if order.fulfillment_status_changed? && order.fulfillment_status == 'fulfilled' && ( order.fulfillment_status == 'unfulfilled' || order.fulfilled_at.blank? )
					order.fulfilled_at = Time.zone.now
				end
				order.save
			end

			redirect_back fallback_location: '/admin'
		end

		def edit
			authorize( @order, :admin_edit? )

			@transactions = Transaction.where( parent_obj: @order )

			set_page_meta( title: "#{@order.code} | Order" )
		end

		def index
			authorize( SwellEcom::Order, :admin? )
			sort_by = params[:sort_by] || 'created_at'
			sort_dir = params[:sort_dir] || 'desc'

			filters = ( params[:filters] || {} ).select{ |attribute,value| not( value.nil? ) }
			filters[:not_trash] = true if params[:q].blank? # don't show trash, unless searching
			filters[:not_archived] = true if params[:q].blank? # don't show archived, unless searching
			filters[ params[:status] ] = true if params[:status].present? && params[:status] != 'all'
			filters[ params[:payment_status] ] = true if params[:payment_status].present? && params[:payment_status] != 'all'
			filters[ params[:fulfillment_status] ] = true if params[:fulfillment_status].present? && params[:fulfillment_status] != 'all'
			@orders = @search_service.order_search( params[:q], filters, page: params[:page], order: { sort_by => sort_dir } )

			set_page_meta( title: "Orders" )
		end

		def refund
			authorize( @order, :admin_refund? )
			refund_amount = ( params[:amount].to_f * 100 ).round

			# check that refund amount doesn't exceed charges?
			# amount_net = Transaction.approved.positive.where( parent: @order ).sum(:amount) - Transaction.approved.negative.where( parent: @order ).sum(:amount)

			@order_service = SwellEcom::OrderService.new

			@transaction = @order_service.refund( amount: refund_amount, order: @order )

			if @transaction.errors.present?

				set_flash @transaction.errors.full_messages, :danger

			elsif @transaction.declined?

				set_flash @transaction.message, :danger

			else

				@order.refunded!

				# cancel fulfillment if a full refund and not already fulfilled/delivered
				@order.fulfillment_canceled! if @order.transactions.approved.negative.sum(:amount) >= @order.transactions.approved.positive.sum(:amount) && not( @order.fulfilled? || @order.delivered? )

				# OrderMailer.refund( @transaction ).deliver_now # send emails on a cron
				set_flash "Refund successful", :success

			end

			redirect_to swell_ecom.edit_order_admin_path( @order )
		end

		def thank_you
			@order = Order.find_by( code: params[:id] )

			render 'swell_ecom/orders/thank_you'
		end


		def update
			authorize( @order, :admin_update? )
			@order.attributes = order_params

			if @order.fulfillment_status_changed? && @order.fulfillment_status == 'fulfilled' && ( @order.fulfillment_status == 'unfulfilled' || @order.fulfilled_at.blank? )
				@order.fulfilled_at = Time.zone.now
			end

			@order.save
			redirect_back fallback_location: '/admin'
		end

		private
			def order_params
				params.require( :order ).permit( :email, :status, :fulfillment_status, :payment_status, :support_notes )
			end

			def get_order
				@order = Order.find_by( id: params[:id] )
			end

			def get_orders
				@orders = Order.where( id: params[:id] )
			end

			def init_search_service
				@search_service = EcomSearchService.new
			end

	end
end
