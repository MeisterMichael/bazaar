
module SwellEcom
	class CheckoutController < ApplicationController
		
		def create
			
			@product = Product.friendly.find( params[:product_id] )
			@amount = @product.price

			customer = Stripe::Customer.create(
				:email => params[:stripeEmail],
				:card  => params[:stripeToken]
			)

			charge = Stripe::Charge.create(
				:customer    => customer.id,
				:amount      => @amount,
				:description => 'Rails Stripe customer',
				:currency    => 'usd'
			)

			if charge.present?
				order = Order.create email: params[:stripeEmail], total: @product.price
				order.order_items.create item: @product
				redirect_to order
			end

			

			rescue Stripe::CardError => e
				set_flash e.message, :danger
				redirect_to success_checkout_index_path

		end



	end
end