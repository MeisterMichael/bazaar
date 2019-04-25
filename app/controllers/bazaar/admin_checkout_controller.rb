
module Bazaar
	class AdminCheckoutController < AdminController

		before_action :get_order, only: [ :create, :new ]
		before_action :initialize_services, only: [ :create, :new ]

		def create
		end

		def new

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

			if @order.user
				@order.email	= @order.user.email if @order.email.blank?

				@billing_geo_addresses	= GeoAddress.where( id: GeoAddress.where( id: @order.user.orders.select(:billing_address_id)  ).where.not( hash_code: @order.user.try(:preferred_billing_address).try(:hash_code)  ).or( GeoAddress.where( id: @order.user.try(:preferred_billing_address_id)  ) ).group(:hash_code).select('MAX(id)') ).order( created_at: :desc )
				@shipping_geo_addresses	= GeoAddress.where( id: GeoAddress.where( id: @order.user.orders.select(:shipping_address_id) ).where.not( hash_code: @order.user.try(:preferred_shipping_address).try(:hash_code) ).or( GeoAddress.where( id: @order.user.try(:preferred_shipping_address_id) ) ).group(:hash_code).select('MAX(id)') ).order( created_at: :desc )

				if @order.respond_to? :billing_address
					@order.billing_address_id	||= @order.user.preferred_billing_address_id
					@order.billing_address_id	||= @billing_geo_addresses.first.try(:id)
				end

				if @order.respond_to? :shipping_address
					@order.shipping_address_id	||= @shipping_geo_addresses.where( hash_code: @order.user.preferred_shipping_address.hash_code ).first.try(:id) if @order.user.preferred_shipping_address
					@order.shipping_address_id	||= @shipping_geo_addresses.first.try(:id)
				end

			begin

				@order_service.calculate( @order,
					# transaction: transaction_options,
					shipping: shipping_options_params,
					# discount: discount_options,
				)

			rescue Exception => e
				puts e
				raise e
				NewRelic::Agent.notice_error(e) if defined?( NewRelic )
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
					:order_offers_attributes => [
						:title,
						:offer_id,
						:quantity,
						:price
					],
				},
			)

			attributes[:status] ||= 'active'
			attributes[:payment_status] ||= 'paid'
			attributes[:status] ||= 'unfulfilled'

			# select order offers with quantity greater than 1
			attributes[:order_offers_attributes] = (attributes[:order_offers_attributes] || []).select{ |index,order_offer_attributes| order_offer_attributes[:quantity].to_i > 0 }
			attributes
		end

		def get_order

			@order = Bazaar::Order.new( get_order_attributes ) if params[:order]
			@order ||= Bazaar::Order.new

			@order.order_offers.to_a.each do |order_offer|
				order_offer.subtotal = order_offer.price * order_offer.quantity
				@order.order_items.new(
					order_item_type: 'prod',
					title: order_offer.title,
					price: order_offer.price,
					subtotal: order_offer.subtotal,
					item: ( Bazaar::Product.where( offer: order_offer.offer ).first || Bazaar::SubscriptionPlan.where( offer: order_offer.offer ).first || Bazaar::WholesaleItem.where( offer: order_offer.offer ).first ),
				)
			end

		end

		def initialize_services
			@fraud_service = Bazaar.fraud_service_class.constantize.new( Bazaar.fraud_service_config.merge( params: params, session: session, cookies: cookies, request: request ) )
			if @order.is_a? Bazaar::WholesaleOrder
				@order_service = Bazaar::WholesaleOrderService.new( fraud_service: @fraud_service )
			else
				@order_service = Bazaar::OrderService.new( fraud_service: @fraud_service )
			end
		end

		def shipping_options_params
			(params.permit( :shipping_options => [ :rate_code, :rate_name, :shipping_carrier_service_id ] )[:shipping_options] || {}).to_h
		end



	end
end
