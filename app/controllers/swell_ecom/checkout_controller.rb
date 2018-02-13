
module SwellEcom
	class CheckoutController < ApplicationController
		include SwellEcom::Concerns::CheckoutConcern

		before_action :get_cart
		before_action :validate_cart, only: [ :confirm, :create, :index ]
		before_action :initialize_services, only: [ :confirm, :create, :index ]
		before_action :get_order, only: [ :confirm, :create, :index ]
		before_action :get_geo_addresses, only: :index

		def confirm

			@order_service.calculate( @order,
				transaction: transaction_options,
				shipping: shipping_options,
			)

		end

		def create

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
				respond_to do |format|
					format.json {
						render :create
					}
					format.html {
						redirect_back fallback_location: '/checkout'
					}
				end
			else
				session[:cart_count] = 0
				session[:cart_id] = nil

				payment_profile_expires_at = SwellEcom::TransactionService.parse_credit_card_expiry( params[:credit_card][:expiration] ) if params[:credit_card].present?
				@subscription_service.subscribe_ordered_plans( @order, payment_profile_expires_at: payment_profile_expires_at ) if @order.active?

				# if current user exists, update it's address info with the
				# billing address, if not already set
				update_order_user_address( @order )

				@cart.update( order_id: @order.id, status: 'success' )

				OrderMailer.receipt( @order ).deliver_now
				#OrderMailer.notify_admin( @order ).deliver_now


				respond_to do |format|
					format.json {
						render :create
					}
					format.html {
						redirect_to swell_ecom.thank_you_order_path( @order.code )
					}
				end

			end


		end

		def index

			@cart.init_checkout!

			add_page_event_data(
				ecommerce: {
					checkout: {
						actionField: {},
						products: @cart.cart_items.collect{|cart_item| cart_item.item.page_event_data.merge( quantity: cart_item.quantity ) }
					}
				}
			);

		end

		def new
			redirect_to checkout_index_path( params.permit(:stripeToken, :credit_card, :coupon, :order ).to_h.merge( controller: nil, action: nil ) )
		end

		def state_input

			@order = Order.new currency: 'usd'
			@order.shipping_address = GeoAddress.new
			@order.billing_address 	= GeoAddress.new

			@address_attribute = ( params[:address_attribute] == 'billing_address' ? :billing_address : :shipping_address )
			@states = SwellEcom::GeoState.where( geo_country_id: params[:geo_country_id] )

			render layout: false

		end


		protected

		def get_cart
			@cart ||= Cart.find_by( id: session[:cart_id] )
		end

		def get_order

			@order = Order.new( get_order_attributes.merge( order_items_attributes: [], user: current_user ) )
			@order.billing_address.user = @order.shipping_address.user = @order.user

			discount = Discount.active.in_progress.find_by( code: params[:coupon] ) if params[:coupon].present?
			order_item = @order.order_items.new( item: discount, order_item_type: 'discount', title: discount.title ) if discount.present?
			@cart.cart_items.each do |cart_item|
				order_item = @order.order_items.new( item: cart_item.item, price: cart_item.price, subtotal: cart_item.subtotal, order_item_type: 'prod', quantity: cart_item.quantity, title: cart_item.item.title, tax_code: cart_item.item.tax_code )
				@order.status = 'pre_order' if order_item.item.respond_to?( :pre_order? ) && order_item.item.pre_order?
			end

		end

		def validate_cart
			if @cart.nil?
				redirect_back fallback_location: '/cart'
				return false
			end
		end



	end
end
