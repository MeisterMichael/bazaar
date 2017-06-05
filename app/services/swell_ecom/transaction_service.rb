module SwellEcom

	class TransactionService

		def self.calculate( order )

			order.total = 0

			order.order_items.each do |order_item|
				order.total = order.total + order_item.subtotal
			end

		end

		def self.process( order, args = {} )

			stripe_token = args[:stripe_token]

			self.calculate( order )

			begin

				# Token is created using Stripe.js or Checkout!
				# Get the payment token submitted by the form:

				customer = Stripe::Customer.create(
					'email' => order.email,
					'card'  => stripe_token
				)

				# Charge the user's card:
				charge = Stripe::Charge.create(
					'customer'		=> customer.id,
					'amount' 		=> order.total,
					'description' 	=> args[:description] || "#{SwellMedia.app_name} order of #{order.order_items.first.title}".truncate(255),
					'currency'		=> order.currency.downcase,
				)


				if charge.present?

					order.save

					# Transaction.create( parent_obj: order, transaction_type: 'charge', reference_code: charge.id, provider: 'Stripe', amount: order.total, currency: order.currency, status: 'approved' )

					return true
				end



			rescue Stripe::CardError => e

				puts e
				order.errors.add(:base, :processing_error, message: "cannot be nil")
				# Transaction.create( parent: order, transaction_type: 'charge', reference: charge.id, provider: 'Stripe', amount: order.total, currency: order.currency, status: 'declined' )

			rescue Stripe::InvalidRequestError => e

				order.errors.add(:base, :processing_error, message: 'Processing error')
				NewRelic::Agent.notice_error(e, custom_params: {
					'e.message' => e.message,
					'email' => order.email,
					'card'  => stripe_token,
					'amount' 	=> order.total,
					'currency'	=> order.currency.downcase,
				} )
				puts e

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
