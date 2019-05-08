
module Bazaar
	class AdminCheckoutController < Bazaar::EcomAdminController

		before_action :get_order, only: [ :edit, :update, :complete ]
		before_action :get_offer_parent_groups, only: [ :edit ]
		before_action :initialize_services, only: [ :edit, :update, :complete ]

		def complete

			begin

				@order.update( status: 'active' )
				@order.shipments.where( status: 'draft' ).update_all( status: 'pending' )
				@order.shipments.not_negative_status.where( processable_at: nil ).update_all( processable_at: Time.now )


				@order.subtotal = @order.order_offers.sum(:subtotal)
				@order.shipping = @order.shipments.not_negative_status.sum(:price)
				@order_service.tax_service.calculate( @order )
				@order.total = @order.subtotal + @order.shipping + @order.tax


				if @order.save
					redirect_to order_admin_path( @order )
				else
					set_flash @order.errors.full_messages, :danger
					redirect_back fallback_location: admin_checkout_index_path
				end

			rescue Exception => e
				puts e
				NewRelic::Agent.notice_error(e) if defined?( NewRelic )
				set_flash "An error occured during processing.", :danger
				redirect_back fallback_location: admin_checkout_index_path
			end
		end

		def create
			@order = Bazaar::Order.new( type: (params[:order] || {})[:type] )
			order_attributes = get_order_attributes
			order_attributes.delete(:billing_address_attributes) if order_attributes[:billing_address_id].to_i.to_s == order_attributes[:billing_address_id]
			order_attributes.delete(:shipping_address_attributes) if order_attributes[:shipping_address_id].to_i.to_s == order_attributes[:shipping_address_id]
			@order.attributes = order_attributes
			@user = @order.user

			if @order.save
				redirect_to edit_admin_checkout_path(@order)
			else
				set_flash @order.errors.full_messages, :danger
				redirect_back fallback_location: admin_checkout_index_path
			end

		end

		def edit

			begin

				@order.subtotal = @order.order_offers.sum(:subtotal)
				@order.shipping = @order.shipments.not_negative_status.sum(:price)
				@order_service.tax_service.calculate( @order )
				@order.total = @order.subtotal + @order.shipping + @order.tax

			rescue Exception => e
				puts e
				raise e
				NewRelic::Agent.notice_error(e) if defined?( NewRelic )
			end


		end

		def update

			order_attributes = get_order_attributes

			billing_address_id = order_attributes[:billing_address_id]
			if order_attributes[:billing_address_id].to_i.to_s == order_attributes[:billing_address_id]
				order_attributes.delete(:billing_address_attributes)
			else
				order_attributes.delete(:billing_address_id)
			end

			shipping_address_id = order_attributes[:shipping_address_id]
			if order_attributes[:shipping_address_id].to_i.to_s == order_attributes[:shipping_address_id]
				order_attributes.delete(:shipping_address_attributes)
			else
				order_attributes.delete(:shipping_address_id)
			end

			order_offers_attributes = order_attributes[:order_offers_attributes]
			if order_offers_attributes.present?
				@order.order_skus.delete_all
				@order.order_offers.delete_all
				@order.order_items.prod.delete_all
			end

			@order.attributes				= order_attributes
			@order.shipping_address	= @order.billing_address if billing_address_id == 'same'
			@order.billing_address	= @order.shipping_address if shipping_address_id == 'same'

			if order_offers_attributes.present?
				@order_service.calculate_prod_order_items( @order )
				@order_service.calculate_order_skus( @order )
			end




			if @order.save
				redirect_to edit_admin_checkout_path( @order, shipping_options: shipping_options_params )
			else
				set_flash @order.errors.full_messages, :danger
				redirect_back fallback_location: admin_checkout_index_path
			end

		end

		def new

			@order = Bazaar::Order.new( type: (params[:order] || {})[:type] )
			order_attributes = get_order_attributes
			@new_billing_address = GeoAddress.new
			@new_shipping_address = GeoAddress.new

			@order.attributes = order_attributes
			@user = @order.user

			if @user
				@billing_geo_addresses	= GeoAddress.where( id: GeoAddress.where( id: @order.user.orders.select(:billing_address_id)  ).where.not( hash_code: @order.user.try(:preferred_billing_address).try(:hash_code)  ).or( GeoAddress.where( id: @order.user.try(:preferred_billing_address_id)  ) ).group(:hash_code).select('MAX(id)') ).order( created_at: :desc )
				@shipping_geo_addresses	= GeoAddress.where( id: GeoAddress.where( id: @order.user.orders.select(:shipping_address_id) ).where.not( hash_code: @order.user.try(:preferred_shipping_address).try(:hash_code) ).or( GeoAddress.where( id: @order.user.try(:preferred_shipping_address_id) ) ).group(:hash_code).select('MAX(id)') ).order( created_at: :desc )
			end

		end

		protected

		def get_order_attributes
			attributes = params.require(:order).permit(
				:status,
				:payment_status,
				:fulfillment_status,
				:email,
				:user_id,
				:type,
				:billing_address_id,
				:shipping_address_id,
				{
					:billing_address_attributes => [ :user_id, :phone, :zip, :geo_country_id, :geo_state_id, :state, :city, :street2, :street, :last_name, :first_name ],
					:shipping_address_attributes => [ :user_id, :phone, :zip, :geo_country_id, :geo_state_id, :state, :city, :street2, :street, :last_name, :first_name ],
					:order_offers_attributes => [
						:title,
						:offer_id,
						:quantity,
						:price
					],
				},
			)

			attributes[:status] ||= 'draft'
			attributes[:payment_status] ||= 'paid'
			attributes[:status] ||= 'unfulfilled'

			# select order offers with quantity greater than 1
			attributes[:order_offers_attributes] = attributes[:order_offers_attributes].select{ |index,order_offer_attributes| order_offer_attributes[:quantity].to_i > 0 } if attributes[:order_offers_attributes]

			attributes
		end

		def get_offer_parent_groups
			if @order.is_a? Bazaar::WholesaleOrder
				@offer_parent_groups = {
					'Wholesale' => Bazaar::WholesaleProfile.find( @order.user.wholesale_profile_id ).wholesale_items.where.not( offer: nil ).joins(:offer).order( 'bazaar_offers.title ASC' ),
				}
			else
				@offer_parent_groups = {
					'Products' => Bazaar::Product.active.published.where.not( offer: nil ).order( title: :asc ),
					'Plans' => Bazaar::SubscriptionPlan.active.published.where.not( offer: nil ).order( title: :asc ),
				}
			end

			if @user
				offer_parents = Bazaar::UserOffer.where( user: @user ).joins(:offer).order( 'bazaar_offers.title ASC' )
				@offer_parent_groups['User Offers'] = offer_parents if offer_parents.present?
			end

			@offer_parent_groups
		end

		def get_order

			@order = Bazaar::Order.find( params[:id] )

		end

		def initialize_services
			@fraud_service = Bazaar.fraud_service_class.constantize.new( Bazaar.fraud_service_config.merge( params: params, session: session, cookies: cookies, request: request ) )
			if @order.is_a? Bazaar::WholesaleOrder
				@order_service = Bazaar::WholesaleOrderService.new(
					fraud_service: @fraud_service,
					# shipping_service: Bazaar::ShippingService.new,
				)
			else
				@order_service = Bazaar::OrderService.new(
					fraud_service: @fraud_service,
					# shipping_service: Bazaar::ShippingService.new,
				)
			end
		end

		def shipping_options_params
			(params.permit( :shipping_options => [ :rate_code, :rate_name, :shipping_carrier_service_id ] )[:shipping_options] || {}).to_h
		end



	end
end
