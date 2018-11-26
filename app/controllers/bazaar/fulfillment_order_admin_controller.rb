module Bazaar
	class FulfillmentOrderAdminController < Bazaar::EcomAdminController

		before_action :get_shipping_service


		def create
			@order = Bazaar::FulfillmentOrder.new order_params
			@order.source = 'fulfillment order admin'

			@order.user ||= User.create_with( first_name: @order.shipping_address.first_name, last_name: @order.shipping_address.last_name ).find_or_create_by( email: @order.email.downcase ) if @order.email.present? && Bazaar.create_user_on_checkout
			Email.create_or_update_by_email( @order.email, user: @order.user )
			@order.shipping_address.user = @order.user

			authorize( @order )

			@shipping_service.calculate( @order ) if @order.shipping_address.validate
			@order.payment_status = 'paid'
			@order.shipping = 0
			@order.total = 0 if @order.total.nil?

			@order.order_items.each do |order_item|
				order_item.title		= order_item.item.title if order_item.title.blank?
				order_item.price		= 0
				order_item.subtotal	= 0
			end

			if @order.save
				set_flash 'Fulfillment Order Created', :success
				redirect_to order_admin_path(@order)
			else

				set_flash @order.nested_errors, :danger
				redirect_back fallback_location: '/fulfillment_admin/new'
			end

		end

		def new
			@order = Bazaar::FulfillmentOrder.new order_params
			@shipping_service.calculate( @order ) if @order.shipping_address.validate
		end

		protected
		def order_params
			return { shipping_address_attributes: {} } unless params[:order].present?
			order_attributes = params.require( :order ).permit(
				:email,
				:currency,
				:status,
				:fulfillment_status,
				:payment_status,
				:support_notes,
				:customer_notes,
				:shipping_address_id,
				{
					:shipping_address_attributes => [
						:phone, :zip, :geo_country_id, :geo_state_id , :state, :city, :street2, :street, :last_name, :first_name,
					],
					:order_items_attributes => [
						:item_polymorphic_id,
						:item_type,
						:item_id,
						:quantity,
						:price,
						:price_as_money,
						:price_as_money_string,
						:subtotal,
						:subtotal_as_money,
						:subtotal_as_money_string,
						:order_item_type,
						:title,
						:tax_code,
					],
				}
			)

			order_attributes
		end

		def shipping_options
			params.permit(shipping_options: {}) || {}
		end

		def get_shipping_service
			@shipping_service		||= Bazaar.shipping_service_class.constantize.new( Bazaar.shipping_service_config )
		end
	end
end
