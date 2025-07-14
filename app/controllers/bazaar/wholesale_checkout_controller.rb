
module Bazaar
	class WholesaleCheckoutController < ApplicationController
		include Bazaar::Concerns::CheckoutConcern
		include Bazaar::Concerns::EcomConcern
		layout 'bazaar/application'

		helper_method :get_billing_countries
		helper_method :get_shipping_countries
		helper_method :get_billing_states
		helper_method :get_shipping_states
		helper_method :discount_options
		helper_method :shipping_options

		before_action :authenticate_user!
		before_action :user_has_wholesale_profile

		before_action :initialize_services, only: [ :create, :index, :calculate, :confirm ]
		before_action :get_order, only: [ :create, :index, :calculate, :confirm ]
		before_action :get_geo_addresses, only: :index

		def calculate

			begin
				@order.billing_user_address ||= UserAddress.new
				@order.shipping_user_address ||= UserAddress.new


				@order.options = {
					transaction: transaction_options,
					shipping: shipping_options,
					discount: discount_options,
				}

				@order_service.calculate( @order, @order.options )

			rescue Exception => e
				puts e
				NewRelic::Agent.notice_error(e) if defined?( NewRelic )
			end

		end

		def confirm

			@order.options = {
				transaction: transaction_options,
				shipping: shipping_options,
				discount: discount_options,
			}

			@order_service.calculate( @order, @order.options )

			render layout: 'bazaar/checkout'
		end

		def create

			@order.status = 'active'
			@order.source = 'Wholesale Checkout'

			@order.order_offers = @order.order_offers.select{|order_offer| order_offer.quantity > 0 }

			@order.options = {
				transaction: transaction_options,
				shipping: shipping_options,
				discount: discount_options,
			}

			@order_service.process( @order, @order.options )

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
						if params[:from] == 'checkout'
							render 'bazaar/wholesale_checkout/index', layout: 'bazaar/checkout'
						else
							render 'bazaar/wholesale_checkout/confirm', layout: 'bazaar/checkout'
						end
					}
				end
			else

				@fraud_service.mark_for_review( @order ) if @fraud_service.suspicious?( @order )

				Bazaar::WholesaleOrderMailer.receipt( @order ).deliver_now if Bazaar.enable_wholesale_order_mailer

				log_event( user: @order.user, name: 'wholesale_purchase', category: 'ecom', value: @order.total, on: @order, content: "placed a wholesale order for $#{@order.total/100.to_f}." )

				respond_to do |format|
					format.js {
						render :create
					}
					format.json {
						render :create
					}
					format.html {
						redirect_to thank_you_wholesale_checkout_path( @order.code )
					}
				end

			end


		end

		def index

			@order.subtotal = @order.order_offers.to_a.sum(&:subtotal)
			@order.total = @order.subtotal

			begin

				@order.options = {
					transaction: transaction_options,
					shipping: shipping_options,
					discount: discount_options,
				}

				@order_service.calculate( @order, @order.options )

			rescue Exception => e
				raise e if Rails.env.development?
				NewRelic::Agent.notice_error(e) if defined?( NewRelic )
			end


			set_page_meta( title: "#{Pulitzer.app_name} - Checkout" )

			render layout: 'bazaar/checkout'
		end

		def thank_you

			@order = current_user.orders.find_by( code: params[:id] )
			raise ActionController::RoutingError.new( 'Not Found' ) unless @order.present?

			# render layout: 'bazaar/checkout'
		end


		def initialize_services
			@fraud_service = Bazaar.fraud_service_class.constantize.new( Bazaar.fraud_service_config.merge( params: params, session: session, cookies: cookies, request: request ) )
			@order_service = Bazaar.wholesale_order_service_class.constantize.new( fraud_service: @fraud_service )
		end


		protected

		def authenticate_user!
			unless current_user.present?
				set_flash "Sign with your wholesale account to continue."
				redirect_to '/login'
				return false
			end
		end

		def get_order

			order_attributes = params.permit(
				order: [
					:email,
					:customer_notes,
					:same_as_billing,
					:same_as_shipping,
					:billing_user_address_id,
					:shipping_user_address_id,
					{
						:order_offers_attributes => [
							:offer_id,
							:quantity,
						],
					},
				]
			).to_h

			order_attributes = order_attributes[:order] || {}

			order_attributes[:billing_user_address]		= current_user.user_addresses.find( order_attributes.delete(:billing_user_address_id) ) if order_attributes[:billing_user_address_id].present?
			order_attributes[:billing_address]				= order_attributes[:billing_user_address].try(:geo_address)

			order_attributes[:shipping_user_address]	= current_user.user_addresses.find( order_attributes.delete(:shipping_user_address_id) ) if order_attributes[:shipping_user_address_id].present?
			order_attributes[:shipping_address]				= order_attributes[:shipping_user_address].try(:geo_address)

			order_attributes[:status]	= 'draft'
			order_attributes[:ip]		= client_ip
			order_attributes[:user]		= current_user
			order_attributes[:currency]	= 'USD'

			@order = Bazaar.wholesale_order_class_name.constantize.new( order_attributes )
			@order.email = @order.user.email if @order.email.blank?

			@wholesale_profile = Bazaar::WholesaleProfile.find( current_user.wholesale_profile_id )

			@order.order_offers.each do |order_offer|

				offer									= @wholesale_profile.offers.where( cart_title: order_offer.offer.cart_title, min_quantity: 0..order_offer.quantity ).order( min_quantity: :desc ).first
				order_offer.offer			= offer if offer
				order_offer.quantity	= [order_offer.quantity,order_offer.offer.min_quantity].max
				order_offer.price			= order_offer.offer.initial_price
				order_offer.subtotal	= order_offer.price * order_offer.quantity
				order_offer.tax_code	= order_offer.offer.tax_code
				order_offer.title			= order_offer.offer.cart_title

			end

			@wholesale_profile.offers.order(min_quantity: :asc).each do |offer|
				unless @order.order_offers.select{|order_offer| order_offer.offer.cart_title.parameterize == offer.cart_title.parameterize }.present?
					order_offer = @order.order_offers.new(
						offer: offer,
						title: offer.cart_title,
						quantity: offer.min_quantity,
						price: offer.initial_price,
						subtotal: 0,
						tax_code: offer.tax_code,
					)

					order_offer.price			= @wholesale_profile.get_price( quantity: order_offer.quantity, offer: order_offer.offer )
					order_offer.price			||= order_offer.offer.initial_price
					order_offer.subtotal	= order_offer.price * order_offer.quantity
				end
			end

		end

		def user_has_wholesale_profile
			unless current_user.wholesale_profile_id.present?
				set_flash "This account does not have access to the wholesale checkout."
				redirect_to '/'
				return false
			end
		end



	end
end
