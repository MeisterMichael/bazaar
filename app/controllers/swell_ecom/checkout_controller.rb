
module SwellEcom
	class CheckoutController < ApplicationController

		def new

			@items = Sku.where( code: params[:sku_codes] )

		end

		def create

			@skus = Sku.where( code: params[:sku_codes] )

			@order = Order.new total: items.sum(:price), email: params[:email]

			@skus.each do |sku|
				@order.order_items.new item: sku, subtotal: sku.price, order_item_type: 'sku'
			end

			begin

				# Stripe.api_key = "sk_test_BQokikJOvBiI2HlWgH4olfQ2"

				# Token is created using Stripe.js or Checkout!
				# Get the payment token submitted by the form:
				stripe_token = params[:stripeToken]

				customer = Stripe::Customer.create(
					:email => @order.user.try(:email) || @order.email,
					:card  => stripe_token
				)

				# Charge the user's card:
				charge = Stripe::Charge.create(
					:customer    => customer.id,
					:amount => @order.total,
					:currency => @order.currency,
				)

				if charge.present?
					@order.save
					redirect_to @order
				end



			rescue Stripe::CardError => e
				set_flash e.message, :danger
				redirect_to :back
			end

		end



	end
end
