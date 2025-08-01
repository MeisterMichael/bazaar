
module Bazaar
	class CheckoutController < ApplicationController
		include Bazaar::Concerns::CheckoutConcern
		include Bazaar::Concerns::EcomConcern
		include Bazaar::Concerns::ApplicationCheckoutConcern if (Bazaar::Concerns::ApplicationCheckoutConcern rescue nil)
		layout 'bazaar/application'

		helper_method :get_billing_countries
		helper_method :get_shipping_countries
		helper_method :get_billing_states
		helper_method :get_shipping_states
		helper_method :discount_options
		helper_method :order_options
		helper_method :shipping_options
		helper_method :log_event

		before_action :get_bazaar_cart
		before_action :calculate_update_cart_discount, only: [ :calculate ]
		before_action :index_update_cart_discount, only: [ :index ]
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

			if @order_service.fraud_service.present? && not( @order_service.fraud_service.valid_order_request?( { order: @order, request: request, cookies: cookies, params: params } ) )
				@order.status = 'failed'
				@order.errors.add( :base, :processing_error, message: 'An error occured during transaction processing.  Please contact support for assistance.' )
				log_event( user: @order.user, on: @order, name: 'invalid_order_request', message: "order failed fraud_service.valid_order_request" )
				#raise Exception.new 'An error occured during transaction processing.  Please contact support for assistance.'

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

				return
			end

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

				clear_bazaar_cart()

				begin
					# if current user exists, update it's address info with the
					# billing address, if not already set
					update_order_user_address( @order )

				rescue Exception => e
					if Rails.env.development?
						puts e.message
						puts e.backtrace
					end
					NewRelic::Agent.notice_error(e) if defined?( NewRelic )
				end

				begin

					@fraud_service.post_processing( @order )

				rescue Exception => e
					if Rails.env.development?
						puts e.message
						puts e.backtrace
					end
					NewRelic::Agent.notice_error(e) if defined?( NewRelic )
				end


				begin

					# Update cart to completed status
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
					Bazaar::OrderMailer.receipt( @order ).deliver_now if Bazaar.enable_checkout_order_mailer
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
					@thank_you_url = bazaar.thank_you_order_path( @order.code, default_url_options.merge( format: :html, t: @expiration.to_i, d: Rails.application.message_verifier('order.id').generate({ code: @order.code, id: @order.id, expiration: @expiration }), from: 'checkout', funnel: params[:funnel].to_s.gsub(/[^a-zA-Z0-9\-]/,'') ) )

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

			@exit_upsell_offers = @upsell_service.find_exit_checkout_offers_for_order( @order )
			@first_exit_upsell_offer = @exit_upsell_offers.first


			@order.shipping_user_address = UserAddress.new( geo_address: GeoAddress.new( geo_country: GeoCountry.new ) )
			@order.billing_user_address = UserAddress.new( geo_address: GeoAddress.new( geo_country: GeoCountry.new ) )
			@order.options = {
				order: order_options,
				transaction: transaction_options,
				shipping: shipping_options,
				discount: discount_options,
			}

			@order_service.calculate( @order, @order.options )

			@cart.init_checkout!

			set_page_meta(
				{
					title: 'Checkout - Neurohacker Collective',
					fb_type: 'article'
				}
			)

			if params[:buy_now] && @cart.cart_offers.present?
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

		def calculate_update_cart_discount

			if @cart.respond_to?( :discount )
				discount = nil

				if ( discount_code = discount_options[:code].to_s ).present?
					Bazaar::Discount.pluck('distinct type').collect(&:constantize) if Rails.env.development?
					discount = Bazaar::CouponDiscount.active.in_progress.where( 'lower(code) = ?', discount_code.downcase ).first
				end
				@cart.update( discount: discount )
			end
		end

		def index_update_cart_discount
			calculate_update_cart_discount if discount_options[:code].present?
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

				if user_attributes[:billing_user_address_attributes].present?
					attributes[:first_name]	= user_attributes[:billing_user_address_attributes][:first_name]
					attributes[:last_name]	= user_attributes[:billing_user_address_attributes][:last_name]
					end

				if attributes[:first_name].blank? && attributes[:last_name].blank? && user_attributes[:shipping_user_address_attributes].present?
					attributes[:first_name]	= user_attributes[:shipping_user_address_attributes][:first_name]
					attributes[:last_name]	= user_attributes[:shipping_user_address_attributes][:last_name]
				end

				@user = User.create_with( first_name: attributes[:first_name], last_name: attributes[:last_name] ).find_or_create_by( email: attributes[:email] )
			end

			if @user.present? && @user.first_name.blank? && @user.last_name.blank? && attributes.present?
				@user.update(
					first_name: attributes[:first_name],
					last_name: attributes[:last_name],
				)
			end

			@user
		end

		def get_order

			@order = Bazaar.checkout_order_class_name.constantize.new( get_order_attributes )

			@cart.cart_offers.each do |cart_offer|
				quantity = cart_offer.quantity
				quantity = [ quantity, cart_offer.offer.per_cart_limit ].min if cart_offer.offer.try(:per_cart_limit).present?

				order_offer = @order.order_offers.new( offer: cart_offer.offer, price: cart_offer.price, subtotal: cart_offer.subtotal, quantity: quantity, title: cart_offer.offer.cart_title, tax_code: cart_offer.offer.tax_code )

				order_offer.source_obj = cart_offer.source_obj if order_offer.respond_to?( :source_obj ) && cart_offer.respond_to?( :source_obj )
				order_offer.source_referrer = cart_offer.source_referrer if order_offer.respond_to?( :source_referrer ) && cart_offer.respond_to?( :source_referrer )
				order_offer.source_medium = cart_offer.source_medium if order_offer.respond_to?( :source_medium ) && cart_offer.respond_to?( :source_medium )

				order_offer.upsell_offer_id = cart_offer.upsell_offer_id if order_offer.respond_to?( :upsell_offer_id ) && cart_offer.respond_to?( :upsell_offer_id )
				order_offer.upsell_id = cart_offer.upsell_id if order_offer.respond_to?( :upsell_id ) && cart_offer.respond_to?( :upsell_id )
				order_offer.bazaar_media_relation_id = cart_offer.bazaar_media_relation_id if order_offer.respond_to?( :bazaar_media_relation_id ) && cart_offer.respond_to?( :bazaar_media_relation_id )

			end

			if @cart.discount.present? && @cart.discount.active? && @cart.discount.in_progress?
				@order.order_items.new( item: @cart.discount, order_item_type: 'discount', title: @cart.discount.title )
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
