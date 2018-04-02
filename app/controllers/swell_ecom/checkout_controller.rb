
module SwellEcom
	class CheckoutController < ApplicationController
		include SwellEcom::Concerns::CheckoutConcern
		include SwellEcom::Concerns::EcomConcern
		layout 'swell_ecom/application'

		helper_method :get_billing_countries
		helper_method :get_shipping_countries
		helper_method :get_billing_states
		helper_method :get_shipping_states
		helper_method :discount_options
		helper_method :shipping_options

		before_action :get_cart
		before_action :validate_cart, only: [ :confirm, :create, :index, :calculate ]
		before_action :initialize_services, only: [ :confirm, :create, :index, :calculate ]
		before_action :get_order, only: [ :confirm, :create, :index, :calculate ]
		before_action :get_geo_addresses, only: :index

		def confirm

			@order_service.calculate( @order,
				transaction: transaction_options,
				shipping: shipping_options,
				discount: discount_options,
			)

			render layout: 'swell_ecom/checkout'
		end

		def calculate

			@shipping_service = SwellEcom.shipping_service_class.constantize.new( SwellEcom.shipping_service_config )

			@shipping_rates = []

			if @cart.present?
				@cart.email = @order.email if @order.email.present? && @order.email.match( Devise::email_regexp ).present?

				if @order.billing_address.present?
					@cart.first_name = @order.billing_address.first_name || @cart.first_name
					@cart.last_name = @order.billing_address.last_name || @cart.last_name
				end

				@cart.checkout_cache[:order_attributes] = get_order_attributes
				@cart.checkout_cache[:shipping_options] = shipping_options
				@cart.checkout_cache[:discount_options] = discount_options

				@cart.save
			end

			begin

				@order_service.calculate( @order,
					transaction: transaction_options,
					shipping: shipping_options,
					discount: discount_options,
				)

				@shipping_rates = @shipping_service.find_rates( @order, shipping_options ) if @order.shipping_address.geo_country.present?
			rescue Exception => e
				puts e
				NewRelic::Agent.notice_error(e) if defined?( NewRelic )
			end
		end

		def create

			@order.user ||= User.create_with( first_name: @order.billing_address.first_name, last_name: @order.billing_address.last_name ).find_or_create_by( email: @order.email.downcase ) if @order.email.present? && SwellEcom.create_user_on_checkout
			@order.billing_address.user = @order.shipping_address.user = @order.user

			@order.billing_address.tags = @order.billing_address.tags + ['billing_address']
			@order.shipping_address.tags = @order.shipping_address.tags + ['shipping_address']

			@order.source = 'Consumer Checkout'

			@order_service.process( @order,
				transaction: transaction_options,
				shipping: shipping_options,
				discount: discount_options,
			)

			if params[:newsletter].present?
				SwellMedia::Optin.create(
					email: @order.email,
					name: "#{@order.billing_address.first_name} #{@order.billing_address.last_name}",
					ip: @order.ip,
					user: @order.user
				)
			end


			if @order.nested_errors.present?
				respond_to do |format|
					format.js {
						render :create
					}
					format.json {
						render :create
					}
					format.html {
						set_flash @order.nested_errors, :danger
						redirect_back fallback_location: '/checkout'
					}
				end
			else
				session[:cart_count] = 0
				session[:cart_id] = nil

				payment_profile_expires_at = SwellEcom::TransactionService.parse_credit_card_expiry( transaction_options[:credit_card][:expiration] ) if transaction_options[:credit_card].present?
				@subscription_service.subscribe_ordered_plans( @order, payment_profile_expires_at: payment_profile_expires_at ) if @order.active?

				# if current user exists, update it's address info with the
				# billing address, if not already set
				update_order_user_address( @order )

				@cart.update( order_id: @order.id, status: 'success' )

				OrderMailer.receipt( @order ).deliver_now
				#OrderMailer.notify_admin( @order ).deliver_now

				@expiration = 30.minutes.from_now.to_i
				@thank_you_url = swell_ecom.thank_you_order_path( @order.code, format: :html, t: @expiration.to_i, d: Rails.application.message_verifier('order.id').generate( code: @order.code, id: @order.id, expiration: @expiration ) )

				if defined?( SwellAnalytics )
					log_analytics_event(
						'purchase',
						event_category: 'swell_ecom',
						country: client_ip_country,
						ip: client_ip,
						user_id: (current_user || @order.user).try(:id),
						referrer_url: request.referrer,
						page_url: request.original_url,
						subject_id: @order.id,
						subject_type: @order.class.base_class.name,
						value: @order.total,
					)
				end

				respond_to do |format|
					format.js {
						render :create
					}
					format.json {
						render :create
					}
					format.html {
						redirect_to @thank_you_url
					}
				end

			end


		end

		def index

			@order.subtotal = @order.order_items.select(&:prod?).sum(&:subtotal)
			@order.total = @order.subtotal

			@cart.init_checkout!

			set_page_meta(
				{
					title: 'Checkout - Neurohacker Collective',
					fb_type: 'article'
				}
			)

			if params[:buy_now]
				add_page_event_data(
					ecommerce: {
						add: {
							actionField: {},
							products: @cart.cart_items.collect{|cart_item| cart_item.item.page_event_data.merge( quantity: cart_item.quantity ) }
						}
					}
				);
			end

			add_page_event_data(
				ecommerce: {
					currencyCode: 'USD',
					checkout: {
						actionField: { step: 1, option: 'Initiate', revenue: @cart.cart_items.to_a.sum(&:subtotal_as_money) },
						products: @cart.cart_items.collect{|cart_item| cart_item.item.page_event_data.merge( quantity: cart_item.quantity ) }
					}
				}
			);



			if defined?( SwellAnalytics )
				log_analytics_event(
					'initiate_checkout',
					event_category: 'swell_ecom',
					country: client_ip_country,
					ip: client_ip,
					user_id: current_user.try(:id),
					referrer_url: request.referrer,
					page_url: request.original_url,
					subject_id: @cart.id,
					subject_type: @cart.class.base_class.name,
					value: @cart.subtotal,
				)
			end

			set_page_meta( title: "#{SwellMedia.app_name} - Checkout" )

			render layout: 'swell_ecom/checkout'
		end

		def new
			redirect_to checkout_index_path( params.permit(:stripeToken, :credit_card, :coupon, :order ).to_h.merge( controller: nil, action: nil ) )
		end


		protected

		def get_cart
			@cart ||= Cart.find_by( id: session[:cart_id] )
		end

		def get_order_attributes
			super().merge( order_items_attributes: [], user: current_user )
		end

		def get_order

			@order = SwellEcom.checkout_order_class_name.constantize.new( get_order_attributes )
			@order.billing_address.user = @order.shipping_address.user = @order.user

			discount = Discount.active.in_progress.where( 'lower(code) = ?', discount_options[:code].downcase ).first if discount_options[:code].present?
			order_item = @order.order_items.new( item: discount, order_item_type: 'discount', title: discount.title ) if discount.present?
			@cart.cart_items.each do |cart_item|
				order_item = @order.order_items.new( item: cart_item.item, price: cart_item.price, subtotal: cart_item.subtotal, order_item_type: 'prod', quantity: cart_item.quantity, title: cart_item.item.title, tax_code: cart_item.item.tax_code )
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
