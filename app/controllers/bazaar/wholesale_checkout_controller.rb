
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
				@order.billing_address ||= GeoAddress.new
				@order.shipping_address ||= GeoAddress.new


				@order_service.calculate( @order,
					transaction: transaction_options,
					shipping: shipping_options,
					discount: discount_options,
				)

			rescue Exception => e
				puts e
				NewRelic::Agent.notice_error(e) if defined?( NewRelic )
			end

		end

		def confirm

			@order_service.calculate( @order,
				transaction: transaction_options,
				shipping: shipping_options,
				discount: discount_options,
			)

			render layout: 'bazaar/checkout'
		end

		def create

			@order.status = 'active'
			@order.source = 'Wholesale Checkout'

			@order.billing_address.user		||= @order.user
			@order.billing_address.tags		= @order.billing_address.tags + ['billing_address']

			@order.shipping_address.user	||= @order.user
			@order.shipping_address.tags	= @order.shipping_address.tags + ['shipping_address']

			@order.order_offers = @order.order_offers.select{|order_offer| order_offer.quantity > 0 }

			@order_service.process( @order,
				transaction: transaction_options,
				shipping: shipping_options,
				discount: discount_options,
			)

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

				WholesaleOrderMailer.receipt( @order ).deliver_now if Bazaar.enable_wholesale_order_mailer

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

			@order.subtotal = @order.order_offers.sum(&:subtotal)
			@order.total = @order.subtotal

			begin

				@order_service.calculate( @order,
					transaction: transaction_options,
					shipping: shipping_options,
					discount: discount_options,
				)

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
			@order_service = Bazaar::WholesaleOrderService.new( fraud_service: @fraud_service )
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
					:billing_address_id,
					:shipping_address_id,
					{
						:billing_address_attributes => [
							:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name,
						],
						:shipping_address_attributes => [
							:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name,
						],
						:order_offers_attributes => [
							:offer_id,
							:quantity,
						],
					},
				]
			).to_h

			order_attributes = order_attributes[:order] || {}

			order_offers_attributes = order_attributes.delete(:order_offers_attributes)

			order_attributes.delete(:shipping_address_attributes) if order_attributes[:shipping_address_id]
			order_attributes.delete(:billing_address_attributes) if order_attributes[:billing_address_id]

			if order_attributes.delete(:same_as_billing)
				order_attributes[:shipping_address_attributes]	= order_attributes[:billing_address_attributes] if order_attributes[:billing_address_attributes]
				order_attributes[:shipping_address_id]			= order_attributes[:billing_address_id] if order_attributes[:billing_address_id]
			end

			if order_attributes.delete(:same_as_shipping)
				order_attributes[:billing_address_attributes]	= order_attributes[:shipping_address_attributes] if order_attributes[:shipping_address_attributes]
				order_attributes[:billing_address_id]			= order_attributes[:shipping_address_id] if order_attributes[:shipping_address_id]
			end

			order_attributes[:status]	= 'draft'
			order_attributes[:ip]		= client_ip
			order_attributes[:user]		= current_user
			order_attributes[:currency]	= 'USD'

			@order = Bazaar.wholesale_order_class_name.constantize.new( order_attributes )
			@order.email = @order.user.email if @order.email.blank?

			@wholesale_profile = Bazaar::WholesaleProfile.find( current_user.wholesale_profile_id )

			@wholesale_items = @wholesale_profile.wholesale_items.order( min_quantity: :desc ).to_a

			offer_quantities = Hash[*order_offers_attributes.values.collect(&:values).flatten.collect(&:to_i)] unless order_offers_attributes.blank?
			offer_quantities ||= Hash[*@wholesale_profile.wholesale_items.where( min_quantity: 0 ).pluck(:offer_id, '0').flatten.collect(&:to_i)]

			offer_quantities.each do |offer_id,quantity|
				wholesale_item = @wholesale_items.find{|this_wholesale_item| this_wholesale_item.offer_id == offer_id }
				wholesale_item = @wholesale_items.find{|this_wholesale_item| this_wholesale_item.item_id == wholesale_item.item_id && this_wholesale_item.item_type == wholesale_item.item_type && this_wholesale_item.min_quantity <= quantity.to_i }

				offer = wholesale_item.offer
				price = offer.offer_prices.active.for_interval( 1 ).first.try(:price)
				subtotal = price * quantity

				order_offer = @order.order_offers.new(
					offer: offer,
					title: wholesale_item.item.title,
					quantity: quantity,
					price: price,
					subtotal: subtotal,
					tax_code: offer.tax_code,
				)

				# @TODO!!!!! append offer_skus
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
