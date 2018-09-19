
module Bazaar
	class CheckoutAdminController < Bazaar::EcomAdminController
		include Bazaar::Concerns::CheckoutConcern
		helper_method :shipping_options
		helper_method :transaction_options

		before_action :get_user
		before_action :initialize_services, only: [ :confirm, :create, :index, :update ]
		before_action :get_order, only: [ :confirm, :create, :index ]

		def confirm
			authorize( @order )

			@order_service.calculate( @order,
				transaction: transaction_options,
				shipping: shipping_options,
			)

		end

		def create
			authorize( @order )

			@order_service.process( @order,
				transaction: transaction_options,
				shipping: shipping_options,
			)

			if params[:newsletter].present?
				Scuttlebutt::Optin.create(
					email: @order.email,
					name: "#{@order.billing_address.first_name} #{@order.billing_address.last_name}",
					ip: @order.ip,
					user: @order.user
				)
			end


			if @order.nested_errors.present?
				set_flash @order.nested_errors, :danger
				get_geo_addresses
				render :index
			else

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
						redirect_to bazaar.thank_you_order_admin_path( @order.code )
					}
				end

			end


		end

		def index
			authorize( Order )
		end

		def state_input
			authorize( Order )

			@order = CheckoutOrder.new currency: 'usd'
			@order.shipping_address = GeoAddress.new
			@order.billing_address 	= GeoAddress.new

			@address_attribute = ( params[:address_attribute] == 'billing_address' ? :billing_address : :shipping_address )
			@states = GeoState.where( geo_country_id: params[:geo_country_id] )

			render 'bazaar/checkout/state_input', layout: false
		end

		def update
			# for processing order pre_orders and drafts
			@order = Bazaar::Order.find( params[:id] )
			authorize( @order )

			if @order.paid?
				set_flash 'Already processed', :danger
				redirect_back fallback_location: '/admin'
				return
			end

			@order_service.process_purchase( @order,
				transaction: transaction_options,
				shipping: shipping_options,
			)

			if @order.nested_errors.present?
				set_flash @order.nested_errors, :danger
				redirect_back fallback_location: '/admin'
			else

				OrderMailer.receipt( @order ).deliver_now

				respond_to do |format|
					format.json {
						render :create
					}
					format.html {
						redirect_to bazaar.thank_you_order_admin_path( @order.code )
					}
				end

			end

		end


		protected

		def get_user
			@user = nil
		end

		def get_order

			@order = Bazaar.checkout_order_class_name.constantize.new( get_order_admin_attributes.merge( user: @user ) )
			@order.user ||= User.find_or_create_by( email: @order.email ) if @order.email.present? && Bazaar.create_user_on_checkout

			@order.billing_address.user = @order.shipping_address.user = @order.user

			discount = Discount.active.in_progress.where( 'lower(code) = ?', discount_options[:code].downcase ).first if params[:coupon].present?
			order_item = @order.order_items.new( item: discount, order_item_type: 'discount', title: discount.title ) if discount.present?

		end

		def get_order_admin_attributes
			order_attributes = get_order_attributes
			order_attributes = order_attributes.merge params.require( :order ).permit( :status, :payment_status, :shipping_status ).to_h if params[:order]

			order_attributes
		end

	end
end
