module SwellEcom
	class OrderAdminController < SwellEcom::EcomAdminController
		include SwellEcom::Concerns::CheckoutConcern
		helper_method :shipping_options
		helper_method :transaction_options

		before_action :initialize_services, only: [ :edit ]


		before_action :get_order, except: [ :index, :create, :new ]
		before_action :initialize_search_service, only: [ :index ]
		before_action :initialize_fraud_service, only: [ :accept, :reject ]

		def accept

			if @fraud_service.accept_review( @order )

				set_flash "Order has been activated.", :success

			end

			redirect_back fallback_location: '/admin'

		end

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
			@order = SwellEcom::CheckoutOrder.new( order_params )
			@order.user = SwellMedia.registered_user_class.constantize.find_by( email: @order.email.downcase )
			@order.user ||= SwellMedia.registered_user_class.constantize.create( email: @order.email.downcase, first_name: @order.billing_address.first_name, last_name: @order.billing_address.last_name )
			@order.total ||= 0
			@order.status = 'draft'

			@order.order_items.select(&:prod?).each do |order_item|
				order_item.title		||= order_item.item.title
				order_item.price		= order_item.item.purchase_price
				order_item.subtotal	= order_item.price * order_item.quantity
				order_item.tax_code	= order_item.item.tax_code
			end

			if @order.save && @order.nested_errors.blank?
				set_flash 'Success.'

				redirect_to edit_order_admin_path( @order.id )
			else
				set_flash @order.nested_errors, :danger

				redirect_back fallback_location: '/order_admin'
			end

		end

		def edit
			unless @order.draft?
				redirect_to order_admin_path( @order )
				return
			end

			authorize( @order, :admin_edit? )

			@order_service.calculate( @order,
				transaction: transaction_options,
				shipping: shipping_options,
				discount: discount_options,
			)

			set_page_meta( title: "#{@order.code} | Order" )
		end

		def index
			authorize( SwellEcom::Order, :admin? )
			sort_by = params[:sort_by] || 'created_at'
			sort_dir = params[:sort_dir] || 'desc'


			filters = ( params[:filters] || {} ).select{ |attribute,value| not( value.nil? ) }
			filters[:type] = @type_filter = ( params[:type] || 'SwellEcom::CheckoutOrder' )
			filters[:not_trash] = true if params[:q].blank? # don't show trash, unless searching
			filters[:not_archived] = true if params[:q].blank? # don't show archived, unless searching
			filters[ params[:status] ] = true if params[:status].present? && params[:status] != 'all'
			filters[ params[:payment_status] ] = true if params[:payment_status].present? && params[:payment_status] != 'all'
			filters[ params[:fulfillment_status] ] = true if params[:fulfillment_status].present? && params[:fulfillment_status] != 'all'
			@orders = @search_service.order_search( params[:q], filters, page: params[:page], order: { sort_by => sort_dir } )

			set_page_meta( title: "Orders" )
		end

		def new
			if params[:order]
				@order = SwellEcom::CheckoutOrder.new order_params
			else
				@order = SwellEcom::CheckoutOrder.new
				@order.billing_address = GeoAddress.new
				@order.shipping_address = GeoAddress.new
			end
			@order.total ||= 0
			@order.status = 'draft'

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

				log_system_event( user: @order.user, name: 'refund', value: -@transaction.amount, on: @order, content: "refunded #{@transaction.amount_formatted} on order #{@order.code}" )

			end

			redirect_to swell_ecom.order_admin_path( @order )
		end

		def reject

			if @fraud_service.reject_review( @order )

				set_flash "Order has been rejected.", :success

			end

			redirect_back fallback_location: '/admin'

		end

		def show
			if @order.draft?
				redirect_to edit_order_admin_path( @order )
				return
			end

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

			@order.order_items.prod.where( quantity: 0 ).destroy_all

			respond_to do |format|
				format.js {
					render :update
				}
				format.json {
					render :update
				}
				format.html {
					set_flash "Order Updated", :success
					redirect_back fallback_location: '/admin'
				}
			end
		end

		private
			def order_params
				order_attributes = params.require( :order ).permit(
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
							:item_polymorphic_id,
							:item_type,
							:item_id,
							:quantity,
							:price,
							:price_as_money,
							:price_as_money_string,
							:subtotal,
							:subtotal_as_money,
							:subtotal_as_money_string,
							:order_item_type,
							:title,
							:tax_code,
						],
					}
				).to_h

				if order_attributes[:order_items_attributes]
					order_attributes[:order_items_attributes] = order_attributes[:order_items_attributes].select{|index, order_item_attributes| order_item_attributes[:quantity].present? }
					order_attributes[:order_items_attributes].each do |index, order_item_attributes|
						order_item_attributes[:order_item_type] = 'prod'
					end
				end

				if order_attributes[:same_as_shipping] == '1' && order_attributes[:shipping_address_attributes].present?
					order_attributes.delete(:same_as_shipping)
					order_attributes[:billing_address_attributes] = order_attributes[:shipping_address_attributes]
				end

				if order_attributes[:same_as_billing] == '1' && order_attributes[:billing_address_attributes].present?
					order_attributes.delete(:same_as_billing)
					order_attributes[:shipping_address_attributes] = order_attributes[:billing_address_attributes]
				end

				order_attributes
			end

			def get_order
				@order = Order.find_by( id: params[:id] )
			end

			def initialize_fraud_service
				@fraud_service = SwellEcom.fraud_service_class.constantize.new( SwellEcom.fraud_service_config )
			end

			def initialize_search_service
				@search_service = EcomSearchService.new
			end

	end
end
