require 'paypal-sdk-rest'

module SwellEcom

	module TransactionServices

		class PayPalExpressCheckoutTransactionService < SwellEcom::TransactionService

			PROVIDER_NAME = 'PayPalExpressCheckout'

			def initialize( args = {} )
				@client_id		= args[:client_id] || ENV['PAYPAL_EXPRESS_CHECKOUT_CLIENT_ID']
				@client_secret	= args[:client_secret] || ENV['PAYPAL_EXPRESS_CHECKOUT_CLIENT_SECRET']
				@mode			= args[:mode] || ENV['PAYPAL_EXPRESS_CHECKOUT_MODE'] || 'sandbox' # or 'live'

				@provider_name	= args[:provider_name] || PROVIDER_NAME
			end



			def capture_payment_method( order, args = {} )
				return false
			end

			def process( order, args = {} )

				payer_id = args[:pay_pal][:payer_id]
				payment_id = args[:pay_pal][:payment_id]

				PayPal::SDK.configure(
					:mode => @mode,
					:client_id => @client_id,
					:client_secret => @client_secret,
					# :ssl_options => { }
				)


				if payment_id.present? && payer_id.present?

					payment = PayPal::SDK::REST::Payment.find(payment_id)

				    if payment.error

						NewRelic::Agent.notice_error( Exception.new("PayPalExpressCheckout Payment Error: #{payment.error}") ) if defined?( NewRelic )
						order.errors.add(:base, :processing_error, message: "Transaction declined.")
						raise Exception.new( payment.error ) if Rails.env.development?

					elsif payment.execute( payer_id: payer_id )

						transaction = SwellEcom::Transaction.create( parent_obj: order, transaction_type: 'charge', reference_code: payment_id, customer_profile_reference: payer_id, provider: @provider_name, amount: order.total, currency: order.currency, status: 'approved' )

						return transaction

					else

						order.errors.add(:base, :processing_error, message: "Transaction declined.")

					end

				else

					NewRelic::Agent.notice_error( Exception.new("PayPalExpressCheckout Payment Error: Payer and/or payment id not present") ) if defined?( NewRelic )
					order.errors.add(:base, :processing_error, message: "Invalid PayPal Credentials.")

				end


				return false
			end

			def provider_name
				@provider_name
			end

			def refund( args = {} )

				transaction = 

				payment = PayPal::SDK::REST::Payment.find(payment_id)

				return false
			end

			def update_subscription_payment_profile( subscription, args = {} )
				return false
			end


		end
	end
end
