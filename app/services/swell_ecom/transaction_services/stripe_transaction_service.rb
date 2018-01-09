module SwellEcom

	module TransactionServices

		class StripeTransactionService < SwellEcom::TransactionService

			def initialize( args = {} )
			end

			def cancel_subscription( subscription )
				# @todo
				throw Exception.new('@todo StripeTransactionService#cancel_subscription')

			end

			def process( order, args = {} )
				self.calculate( order )
				return false if order.errors.present?

				stripe_token = args[:stripeToken]

				begin

					# Token is created using Stripe.js or Checkout!
					# Get the payment token submitted by the form:

					customer = Stripe::Customer.create(
						'email' => order.email,
						'card'  => stripe_token
					)

					# @todo process subscription if order includes a plan, do something different
					# Charge the user's card:
					charge = Stripe::Charge.create(
						'customer'		=> customer.id,
						'amount' 		=> order.total,
						'description' 	=> args[:description] || "#{SwellMedia.app_name} order of #{order.order_items.first.title}".truncate(255),
						'currency'		=> order.currency.downcase,
					)


					if charge.present?

						order.payment_status = 'paid'

						order.save

						Transaction.create( parent_obj: order, transaction_type: 'charge', reference_code: charge.id, provider: 'Stripe', amount: order.total, currency: order.currency, status: 'approved' )

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

			def refund( args = {} )
				# @todo
				throw Exception.new('@todo StripeTransactionService#refund')

			end

			def update_subscription( subscription )
				# @todo
				throw Exception.new('@todo StripeTransactionService#refund')

			end

		end

	end

end
