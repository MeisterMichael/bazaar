
module Bazaar
	class CheckoutController < ApplicationController
		include Bazaar::Concerns::CheckoutConcern
		include Bazaar::Concerns::EcomConcern
		layout 'bazaar/application'

		helper_method :get_billing_countries
		helper_method :get_shipping_countries
		helper_method :get_billing_states
		helper_method :get_shipping_states
		helper_method :discount_options
		helper_method :order_options
		helper_method :shipping_options

		before_action :get_cart
		before_action :validate_cart, only: [ :confirm, :create, :index, :calculate ]
		before_action :initialize_services, only: [ :confirm, :create, :index, :calculate ]
		before_action :get_user, only: [ :create ]
		before_action :get_order, only: [ :confirm, :create, :index, :calculate ]
		before_action :get_geo_addresses, only: :index

		def confirm
			@order.options = {
				order: order_options,
				transaction: transaction_options,
				shipping: shipping_options,
				discount: discount_options,
			}

			@order_service.calculate( @order, @order.options )

			render layout: 'bazaar/checkout'
		end

		def calculate

			@shipping_service = Bazaar.shipping_service_class.constantize.new( Bazaar.shipping_service_config )

			if @cart.present?
				@cart.email = @order.email if @order.email.present? && @order.email.match( Devise::email_regexp ).present?

				if @order.billing_user_address.present?
					@cart.first_name = @order.billing_user_address.first_name || @cart.first_name
					@cart.last_name = @order.billing_user_address.last_name || @cart.last_name
				end

				order_offers_attributes = @order.order_offers.collect do |order_offer|
					order_offer.attributes.to_h.select{ |key,val| not( ['id','updated_at','created_at','order_id'].include?( key.to_s ) ) }
				end

				order_attributes = get_order_attributes.merge( order_offers_attributes: order_offers_attributes )
				order_attributes = order_attributes.to_h.select{ |key,val| not( ['id','updated_at','created_at','user_id', 'user'].include?( key.to_s ) ) }

				@cart.checkout_cache[:order_attributes] = order_attributes
				@cart.checkout_cache[:shipping_options] = shipping_options
				@cart.checkout_cache[:discount_options] = discount_options

				@cart.save

				Email.create_or_update_by_email( @cart.email, user: current_user )
			end

			begin
				@order.options = {
					order: order_options,
					transaction: transaction_options,
					shipping: shipping_options,
					discount: discount_options,
				}

				@order_service.calculate( @order, @order.options )

			rescue Exception => e
				puts e
				NewRelic::Agent.notice_error(e) if defined?( NewRelic )
				raise e if Rails.env.development?
			end

			log_event( name: 'init_checkout', value: @cart.subtotal, on: @cart, content: "started checkout process", ttl: 10.minutes )
		end

		def create
			Email.create_or_update_by_email( @order.email, user: @order.user )
			@order.billing_user_address.user = @order.shipping_user_address.user = @order.user

			@order.source = 'Consumer Checkout'

			begin
				@order.options = {
					order: order_options,
					transaction: transaction_options.merge( default_parent_obj: @cart ),
					shipping: shipping_options,
					discount: discount_options,
				}

				@order_service.process( @order, @order.options )
			rescue Exception => e
				if Rails.env.development?
					puts e.message
					puts e.backtrace
				end

				@order.errors.add( :base, :processing_error, message: 'An error occured during transaction processing.  Please contact support for assistance.' ) if @order.failed?
				log_event( user: @order.user, on: @order, name: 'error', message: "#{e.class.name} - #{e.message}" )
				raise e
			end

			if params[:newsletter].present?
				Scuttlebutt::Optin.create(
					email: @order.email,
					name: "#{@order.billing_user_address.first_name} #{@order.billing_user_address.last_name}",
					ip: @order.ip,
					user: @order.user
				)
			end


			if ( @order.pre_order? && @order.payment_method_captured? ) || ( @order.active? && @order.paid? )
				order_is_pre_order = @order.pre_order?

				session[:cart_count] = 0
				session[:cart_id] = nil

				begin
					# if current user exists, update it's address info with the
					# billing address, if not already set
					update_order_user_address( @order )

					@fraud_service.post_processing( @order )

					@cart.update( order_id: @order.id, status: 'success' )

					# transfer declined transactions from cart to order
					# Bazaar::Transaction.where( parent_obj: @cart ).each do |transaction|
					# 	transaction.update( parent_obj: @order )
					# end
				rescue Exception => e
					if Rails.env.development?
						puts ex.message
						puts ex.backtrace
					end
					NewRelic::Agent.notice_error(e) if defined?( NewRelic )
				end

				begin
					OrderMailer.receipt( @order ).deliver_now if Bazaar.enable_checkout_order_mailer
					#OrderMailer.notify_admin( @order ).deliver_now
				rescue Exception => e
					if Rails.env.development?
						puts e.message
						puts e.backtrace
					end
					NewRelic::Agent.notice_error(e) if defined?( NewRelic )
				end

				begin
					@expiration = 30.minutes.from_now.to_i
					@thank_you_url = bazaar.thank_you_order_path( @order.code, format: :html, t: @expiration.to_i, d: Rails.application.message_verifier('order.id').generate( code: @order.code, id: @order.id, expiration: @expiration ), from: 'checkout', funnel: params[:funnel].to_s.gsub(/[^a-zA-Z0-9\-]/,'') )

					if order_is_pre_order
						log_event( user: @order.user, name: 'pre_order', category: 'ecom', value: @order.total, on: @order, content: "placed a pre-order for $#{@order.total/100.to_f}." )
					else
						log_event( user: @order.user, name: 'purchase', value: @order.total, on: @order, content: "placed an order for $#{@order.total/100.to_f}." )
					end
				rescue Exception => e
					if Rails.env.development?
						puts e.message
						puts e.backtrace
					end
					NewRelic::Agent.notice_error(e) if defined?( NewRelic )
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

			else

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

			end


		end

		def index

			@upsell_offers = @upsell_service.find_at_checkout_offers_for_order( @order )
			@first_upsell_offer = @upsell_offers.first

			@order.subtotal = @order.order_offers.to_a.sum(&:subtotal)
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
							products: @cart.cart_offers.collect{|cart_offer| cart_offer.offer.page_event_data.merge( quantity: cart_offer.quantity ) }
						}
					}
				);
			end

			add_page_event_data(
				ecommerce: {
					currencyCode: 'USD',
					checkout: {
						actionField: { step: 1, option: 'Initiate', revenue: @cart.cart_offers.to_a.sum(&:subtotal_as_money) },
						products: @cart.cart_offers.collect{|cart_offer| cart_offer.offer.page_event_data.merge( quantity: cart_offer.quantity ) }
					}
				}
			);

			log_event( on: @cart )

			set_page_meta( title: "#{Pulitzer.app_name} - Checkout" )

			render layout: 'bazaar/checkout'
		end

		def new
			redirect_to checkout_index_path( params.permit(:stripeToken, :credit_card, :coupon, :order ).to_h.merge( controller: nil, action: nil ) )
		end


		protected

		def get_cart
			@cart ||= Cart.find_by( id: session[:cart_id] )
		end

		def get_order_attributes
			attrs = super().merge( order_offers_attributes: [], user: @user )
			attrs[:billing_user_address_attributes][:user] = @user
			attrs[:shipping_user_address_attributes][:user] = @user
			attrs
		end

		def get_user
			@user = current_user

			if Bazaar.create_user_on_checkout && @user.blank? && params[:order].present? && params[:order][:email].present?
				user_attributes = params.require( :order ).permit( :email, billing_user_address_attributes: [:first_name,:last_name], shipping_user_address_attributes: [:first_name,:last_name] )
				attributes = {
					email: user_attributes[:email].downcase,
				}

				attributes[:first_name]	= user_attributes[:billing_user_address_attributes][:first_name]	if user_attributes[:first_name].blank? && user_attributes[:billing_user_address_attributes].present?
				attributes[:last_name]	= user_attributes[:billing_user_address_attributes][:last_name]	if user_attributes[:last_name].blank? && user_attributes[:billing_user_address_attributes].present?

				attributes[:first_name]	= user_attributes[:shipping_user_address_attributes][:first_name]	if user_attributes[:first_name].blank? && user_attributes[:shipping_user_address_attributes].present?
				attributes[:last_name]	= user_attributes[:shipping_user_address_attributes][:last_name]	if user_attributes[:last_name].blank? && user_attributes[:shipping_user_address_attributes].present?

				@user = User.create_with( first_name: attributes[:first_name], last_name: attributes[:last_name] ).find_or_create_by( email: attributes[:email] )
			end

			@user
		end

		def get_order

			@order = Bazaar.checkout_order_class_name.constantize.new( get_order_attributes )

			@cart.cart_offers.each do |cart_offer|
				@order.order_offers.new( offer: cart_offer.offer, price: cart_offer.price, subtotal: cart_offer.subtotal, quantity: cart_offer.quantity, title: cart_offer.offer.cart_title, tax_code: cart_offer.offer.tax_code )
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
