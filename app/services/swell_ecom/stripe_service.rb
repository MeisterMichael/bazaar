module SwellEcom

	class StripeService

		def self.process( order, stripe_token )

			order.total = 0

			order.order_items.each do |order_item|
				puts order_item.label
				puts order_item.amount
				order.total = order.total + order_item.amount
			end

			begin

				# Token is created using Stripe.js or Checkout!
				# Get the payment token submitted by the form:

				puts "order.total"
				puts order.total

				puts "stripe_token"
				puts stripe_token

				customer = Stripe::Customer.create(
					'email' => order.email,
					'card'  => stripe_token
				)

				puts "customer"
				puts customer.id

				# Charge the user's card:
				charge = Stripe::Charge.create(
					'customer'	=> customer.id,
					'amount' 	=> order.total,
					'currency'	=> order.currency,
				)


				if charge.present?

					order.save

					Transaction.create( parent: order, transaction_type: 'charge', reference: charge.id, provider: 'Stripe', amount: order.total, currency: order.currency, status: 'approved' )

					return true
				end



			rescue Stripe::CardError => e

				order.errors.add(:base, :processing_error, message: "cannot be nil")
				# Transaction.create( parent: order, transaction_type: 'charge', reference: charge.id, provider: 'Stripe', amount: order.total, currency: order.currency, status: 'declined' )


			end

			return false

		end

=begin
		def self.calculate( order )

			begin

				# Token is created using Stripe.js or Checkout!
				# Get the payment token submitted by the form:

				stripe_order_attributes = {
					'currency' => order.currency
					'shipping[name]' => order.shipping_address.full_name
					'shipping[address][line1]' => order.shipping_address.street
					'shipping[address][line2]' => order.shipping_address.street2
					'shipping[address][postal_code]' => order.shipping_address.zip
					'shipping[address][city]' => order.shipping_address.city
					'shipping[address][state]' => order.shipping_address.geo_state.code
					'shipping[address][country]' => order.shipping_address.geo_contry.code
					'email' => order.email
				}

				puts "stripe_order_attributes"
				puts stripe_order_attributes.to_json


				order.order_items.each do |order_item|

					'items[][parent]' => order_item.item.properties['stripe_id']

				end

				stripe_order = Stripe::Order.create(stripe_order_attributes)

				puts order


			rescue Stripe::CardError => e
				set_flash e.message, :danger
				redirect_to :back
			end


			order.total = order.order_items.sum(&:subtotal)

			return

		end
=end

	end

end
