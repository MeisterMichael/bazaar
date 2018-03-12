module SwellEcom
	class OrderAdminController < SwellEcom::EcomAdminController
		include SwellEcom::Concerns::CheckoutConcern
		helper_method :shipping_options
		helper_method :transaction_options

		before_action :initialize_services, only: [ :confirm, :create, :index, :update ]


		before_action :get_order, except: [ :index, :create, :new ]
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

		def create
			@order = SwellEcom::Order.create( order_params )

			if @order.nested_errors.present?
				set_flash @order.nested_errors, :danger
			else
				set_flash 'Success.'
			end

			redirect_back fallback_location: '/order_admin'
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

		def new
			@order = SwellEcom::Order.new order_params

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

			redirect_to swell_ecom.order_admin_path( @order )
		end

		def show
			authorize( @order, :admin_show? )

			@transactions = Transaction.where( parent_obj: @order )

			set_page_meta( title: "#{@order.code} | Order" )
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
				params.require( :order ).permit(
					:email,
					:ip,
					:currency,
					:status,
					:fulfillment_status,
					:payment_status,
					:support_notes,
					:customer_notes,
					:same_as_billing,
					:same_as_shipping,
					{
						:billing_address_attributes => [
							:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name,
						],
						:shipping_address_attributes => [
							:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name,
						],
						:order_items_attributes => [
							:item_type,
							:item_id,
							:quantity,
							:price,
							:order_item_type,
							:title,
							:price,
							:subtotal,
							:tax_code,
						],
					}
				)
			end

			def get_order
				@order = Order.find_by( id: params[:id] )
			end

			def init_search_service
				@search_service = EcomSearchService.new
			end

	end
end
