module Bazaar
	class FulfillmentAdminController < Bazaar::EcomAdminController

		before_action :get_shipping_service


		def create
			@order = Bazaar::Order.find( params[:order_id] )
			authorize( @order )

			begin
				@shipping_service.fulfill_order( @order )
				set_flash "Shipment has been succesfully posted."
			rescue Exception => e
				raise e if Rails.env.development?
				set_flash "An error has occured while attempting to post your shipment."
				NewRelic::Agent.notice_error( e )
			end

			redirect_back fallback_location: order_admin_path(@order)
		end

		def destroy
			@order = Bazaar::Order.find( params[:id] )
			authorize( @order )

			begin
				@shipping_service.cancel_order_fulfillment( @order )
				@order.fulfillment_canceled!
				set_flash "Shipment has been succesfully canceled."
			rescue Exception => e
				raise e if Rails.env.development?
				set_flash "An error has occured while attempting to cancel your shipment."
				NewRelic::Agent.notice_error( e )
			end

			redirect_back fallback_location: order_admin_path(@order)
		end

		protected
		def get_shipping_service
			@shipping_service		||= Bazaar.shipping_service_class.constantize.new( Bazaar.shipping_service_config )
		end
	end
end
