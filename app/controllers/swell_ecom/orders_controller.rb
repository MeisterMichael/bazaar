module SwellEcom
	class OrdersController < ApplicationController

		def thank_you
			@order = Order.find_by( code: params[:id] )

			if @order.user.present?
				raise ActionController::RoutingError.new( 'Not Found' ) if current_user != @order.user
			else
				verified_message = Rails.application.message_verifier('order.id').verify(params[:d])
				raise ActionController::RoutingError.new( 'Not Found' ) unless verified_message[:id] == @order.id && verified_message[:code] == params[:id] && verified_message[:expiration].to_s == params[:t]
				raise ActionController::RoutingError.new( 'Not Found' ) if Time.now.to_i > params[:t].to_i
			end

			add_page_event_data(
				ecommerce: {
					purchase: {
						actionField: {
							id: @order.code,
							revenue: @order.subtotal,
							tax: @order.tax,
							shipping: @order.shipping,
						},
						products: @order.order_items.prod.collect{|order_item| order_item.item.page_event_data.merge( quantity: order_item.quantity ) }
					}
				}
			);

		end

	end
end
