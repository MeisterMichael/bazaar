module Bazaar
	class OrdersController < ApplicationController
		layout 'bazaar/application'

		def thank_you
			@order = Order.find_by( code: params[:id] )


			begin
				if current_user.present?
					raise ActionController::RoutingError.new( 'Not Found' ) if current_user != @order.user
				else
					verified_message = Rails.application.message_verifier('order.id').verify(params[:d])
					raise ActionController::RoutingError.new( 'Not Found' ) unless verified_message[:id] == @order.id && verified_message[:code] == params[:id] && verified_message[:expiration].to_s == params[:t]
					raise ActionController::RoutingError.new( 'Not Found' ) if Time.now.to_i > params[:t].to_i
				end
			rescue Exception => e
				set_flash 'Your session has expired, please login to continue'
				redirect_to '/login'
				return false
			end

			set_page_meta(
				{
					title: 'Thank You for your Order - Neurohacker Collective',
					fb_type: 'article'
				}
			)

			log_event( on: @order )

			@first_purchase_event = @order.properties['purchase_event_fired_at'].blank? || params[:force_purchase_event].present?

			if @first_purchase_event && @order.is_a?( Bazaar::CheckoutOrder ) && not( @order.subscription_renewal? )
				add_page_event_data(
					ecommerce: {
						currencyCode: @order.currency.try(:upcase),
						purchase: {
							actionField: {
								id: @order.code,
								revenue: @order.subtotal_as_money - @order.discount_as_money,
								tax: @order.tax_as_money,
								shipping: @order.shipping_as_money,
							},
							products: @order.order_offers.collect{|order_offer| order_offer.offer.page_event_data.merge( quantity: order_offer.quantity, price: order_offer.price_as_money ) }
						}
					}
				);

				if @order.properties['purchase_event_fired_at'].blank?
					@order.properties = @order.properties.merge( 'purchase_event_fired_at' => Time.now.to_i )
					@order.save
				end
			end

		end

	end
end
