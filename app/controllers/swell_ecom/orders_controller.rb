module SwellEcom
	class OrdersController < ApplicationController

		def thank_you
			@order = Order.find_by( code: params[:id] )


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
