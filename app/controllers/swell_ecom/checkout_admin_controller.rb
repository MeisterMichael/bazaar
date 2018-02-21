
module SwellEcom
	class CheckoutAdminController < SwellMedia::AdminController
		include SwellEcom::Concerns::CheckoutConcern
		helper_method :shipping_options
		helper_method :transaction_options

		before_action :get_user
		before_action :initialize_services, only: [ :confirm, :create, :index ]
		before_action :get_order, only: [ :confirm, :create, :index ]
		before_action :get_geo_addresses, only: :index

		def confirm
			authorize( @order, :admin_create? )

			@order_service.calculate( @order,
				transaction: transaction_options,
				shipping: shipping_options,
			)

		end

		def create
			authorize( @order, :admin_create? )

			@order_service.process( @order,
				transaction: transaction_options,
				shipping: shipping_options,
			)

			if params[:newsletter].present?
				SwellMedia::Optin.create(
					email: @order.email,
					name: "#{@order.billing_address.first_name} #{@order.billing_address.last_name}",
					ip: @order.ip,
					user: @order.user
				)
			end


			if @order.errors.present?
				set_flash @order.errors.full_messages, :danger
				get_geo_addresses
				render :index
			else

				payment_profile_expires_at = SwellEcom::TransactionService.parse_credit_card_expiry( params[:credit_card][:expiration] ) if params[:credit_card].present?
				@subscription_service.subscribe_ordered_plans( @order, payment_profile_expires_at: payment_profile_expires_at ) if @order.active?

				# if current user exists, update it's address info with the
				# billing address, if not already set
				update_order_user_address( @order )

				OrderMailer.receipt( @order ).deliver_now
				#OrderMailer.notify_admin( @order ).deliver_now


				respond_to do |format|
					format.json {
						render :create
					}
					format.html {
						redirect_to swell_ecom.thank_you_order_admin_path( @order.code )
					}
				end

			end


		end

		def index
			authorize( Order, :admin_checkout? )
		end

		def state_input
			authorize( Order, :admin_checkout? )

			@order = Order.new currency: 'usd'
			@order.shipping_address = GeoAddress.new
			@order.billing_address 	= GeoAddress.new

			@address_attribute = ( params[:address_attribute] == 'billing_address' ? :billing_address : :shipping_address )
			@states = SwellEcom::GeoState.where( geo_country_id: params[:geo_country_id] )

			render 'swell_ecom/checkout/state_input', layout: false
		end


		protected

		def get_user
			@user = nil
		end

		def get_order

			@order = Order.new( get_order_admin_attributes.merge( user: @user ) )
			@order.billing_address.user = @order.shipping_address.user = @order.user

			discount = Discount.active.in_progress.find_by( code: params[:coupon] ) if params[:coupon].present?
			order_item = @order.order_items.new( item: discount, order_item_type: 'discount', title: discount.title ) if discount.present?

		end

		def get_order_admin_attributes
			order_attributes = get_order_attributes
			order_attributes = order_attributes.merge params.require( :order ).permit( :status, :payment_status, :shipping_status ).to_h if params[:order]

			order_attributes
		end

	end
end
