
module SwellEcom
	class WholesaleCheckoutController < ApplicationController
		include SwellEcom::Concerns::CheckoutConcern
		include SwellEcom::Concerns::EcomConcern
		layout 'swell_ecom/application'

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

			@shipping_rates = []
			begin

				@order_service.calculate( @order,
					transaction: transaction_options,
					shipping: shipping_options,
					discount: discount_options,
				)

				@shipping_rates = @order_service.shipping_service.find_rates( @order, shipping_options ) if @order.shipping_address.geo_country.present?
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

			render layout: 'swell_ecom/checkout'
		end

		def create

			@order.status = 'active'
			@order.billing_address.user = @order.shipping_address.user = @order.user
			@order.source = 'Wholesale Checkout'

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
							render 'swell_ecom/wholesale_checkout/index', layout: 'swell_ecom/checkout'
						else
							render 'swell_ecom/wholesale_checkout/confirm', layout: 'swell_ecom/checkout'
						end
					}
				end
			else

				WholesaleOrderMailer.receipt( @order ).deliver_now

				if defined?( SwellAnalytics )
					log_analytics_event(
						'purchase',
						event_category: 'swell_ecom_wholesale',
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
						redirect_to thank_you_wholesale_checkout_path( @order.code )
					}
				end

			end


		end

		def index

			@order.subtotal = @order.order_items.select(&:prod?).sum(&:subtotal)
			@order.total = @order.subtotal

			begin

				@order_service.calculate( @order,
					transaction: transaction_options,
					shipping: shipping_options,
					discount: discount_options,
				)

			rescue Exception => e
				puts e
				NewRelic::Agent.notice_error(e) if defined?( NewRelic )
			end

			# if params[:buy_now]
			# 	add_page_event_data(
			# 		ecommerce: {
			# 			add: {
			# 				actionField: {},
			# 				products: @order.order_items.select(&:prod?).collect{|order_item| order_item.item.page_event_data.merge( quantity: order_item.quantity ) }
			# 			}
			# 		}
			# 	);
			# end

			# add_page_event_data(
			# 	ecommerce: {
			# 		currencyCode: 'USD',
			# 		checkout: {
			# 			actionField: { step: 1, option: 'Initiate', revenue: @order.order_items.select(&:prod?).sum(&:subtotal_as_money) },
			# 			products: @order.order_items.select(&:prod?).collect{|order_item| order_item.item.page_event_data.merge( quantity: order_item.quantity ) }
			# 		}
			# 	}
			# );



			if defined?( SwellAnalytics )
				log_analytics_event(
					'initiate_checkout',
					event_category: 'swell_ecom_wholesale',
					country: client_ip_country,
					ip: client_ip,
					user_id: current_user.try(:id),
					referrer_url: request.referrer,
					page_url: request.original_url,
				)
			end

			set_page_meta( title: "#{SwellMedia.app_name} - Checkout" )

			render layout: 'swell_ecom/checkout'
		end

		def thank_you

			@order = current_user.orders.find_by( code: params[:id] )
			raise ActionController::RoutingError.new( 'Not Found' ) unless @order.present?

			# render layout: 'swell_ecom/checkout'
		end


		def initialize_services
			@order_service = SwellEcom::WholesaleOrderService.new
		end


		protected

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
						:order_items_attributes => [
							:item_type,
							:item_id,
							:item_polymorphic_id,
							:quantity,
						],
					},
				]
			).to_h

			order_attributes = order_attributes[:order] || {}

			order_attributes[:shipping_address_attributes]	||= { phone: current_user.phone, zip: current_user.zip, state: current_user.state, city: current_user.city, street2: current_user.address2, street: current_user.address1, last_name: current_user.last_name, first_name: current_user.first_name, } unless order_attributes[:shipping_address_id]
			order_attributes[:billing_address_attributes]	||= { phone: current_user.phone, zip: current_user.zip, state: current_user.state, city: current_user.city, street2: current_user.address2, street: current_user.address1, last_name: current_user.last_name, first_name: current_user.first_name, } unless order_attributes[:billing_address_id]

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

			order_attributes[:order_items_attributes] = order_attributes[:order_items_attributes].values.select{|order_item_attributes| order_item_attributes[:quantity].to_i > 0 } if order_attributes[:order_items_attributes]

			@order = SwellEcom.wholesale_order_class_name.constantize.new( order_attributes )
			@order.email = @order.user.email if @order.email.blank?
			@order.billing_address.user = @order.shipping_address.user = @order.user


			@wholesale_profile = SwellEcom::WholesaleProfile.find( current_user.wholesale_profile_id )

			@order.order_items.each do |order_item|

				order_item.price			= @wholesale_profile.get_price( quantity: order_item.quantity, item: order_item.item )
				order_item.price			||= order_item.item.price
				order_item.subtotal			= order_item.price * order_item.quantity
				order_item.tax_code			= order_item.item.tax_code
				order_item.title			= order_item.item.title
				order_item.order_item_type	= 'prod'

			end


		end

		def user_has_wholesale_profile
			raise ActionController::RoutingError.new( 'Not Found' ) unless current_user.wholesale_profile_id.present?
		end



	end
end
