# require 'paypal-sdk-rest'

module BazaarCore

	module TransactionServices

		class PayPalExpressCheckoutTransactionService < BazaarCore::TransactionService

			PROVIDER_NAME = 'PayPalExpressCheckout'

			def initialize( args = {} )
				raise Exception.new('add "gem \'paypal-checkout-sdk\'" to your Gemfile') unless defined?( PayPalCheckoutSdk )

				@client_id		= args[:client_id] || ENV['PAYPAL_EXPRESS_CHECKOUT_CLIENT_ID']
				@client_secret	= args[:client_secret] || ENV['PAYPAL_EXPRESS_CHECKOUT_CLIENT_SECRET']
				@mode			= args[:mode] || ENV['PAYPAL_EXPRESS_CHECKOUT_MODE'] || 'sandbox' # or 'live'

				@provider_name	= args[:provider_name] || PROVIDER_NAME

				if @mode == 'sandbox'
					@environment = PayPal::SandboxEnvironment.new( @client_id, @client_secret )
				else
					@environment = PayPal::LiveEnvironment.new( @client_id, @client_secret )
				end

				@client = PayPal::PayPalHttpClient.new( @environment )
			end



			def capture_payment_method( order, args = {} )
				order.provider = @provider_name
				order.payment_status = 'declined'
				order.save
				log_event( user: user, on: order, name: 'error', content: "Unable to process capture with PayPal" )

				order.errors.add(:base, "Unable to process this payment method")
				return false
			end

			def process( order, args = {} )

				pay_pal_payer_id = args[:pay_pal][:payer_id]
				pay_pal_payment_id = args[:pay_pal][:payment_id]
				pay_pal_order_id = args[:pay_pal][:order_id]
				pay_pal_payment_token = args[:pay_pal][:payment_token]



				# order.payment_status = 'payment_method_captured'
				order.provider = @provider_name

				order.provider_customer_profile_reference = pay_pal_payer_id
				order.provider_customer_payment_profile_reference = pay_pal_order_id
				order.save

				transaction = BazaarCore::Transaction.create(
					parent_obj: order,
					transaction_type: 'charge',
					reference_code: pay_pal_order_id,
					customer_profile_reference: pay_pal_payer_id,
					customer_payment_profile_reference: pay_pal_payment_id,
					provider: @provider_name,
					amount: order.total,
					currency: order.currency,
					status: 'declined'
				)

				request = PayPalCheckoutSdk::Orders::OrdersCaptureRequest::new( pay_pal_order_id )

				begin

					response = @client.execute(request)
					paypal_order = response.result

				rescue Exception => e
					# Something went wrong server-side

					execption_message = e.message
					exception_message = e.result.message if e.respond_to? :result

					transaction.message = "PayPalExpressCheckout Payment Error: An Error Occured while executing the authorization request. #{exception_message}"
					transaction.save

					NewRelic::Agent.notice_error( e ) if defined?( NewRelic )
					order.errors.add(:base, :processing_error, message: "An error occured while authorizing your Paypal transaction.")

					return transaction

				end

				if paypal_order.present?

					purchase_units = paypal_order.purchase_units
					purchase_units = [purchase_units] unless purchase_units.is_a? Array

					reference_codes = []

					payment_amount = purchase_units.sum do |purchase_unit|
						payments = purchase_unit.payments
						payments = [payments] unless payments.is_a? Array

						payments.sum do |payment|
							captures = payment.captures
							captures = [captures] unless captures.is_a? Array

							captures.sum do |capture|

								reference_codes << capture.id

								( capture.amount.value.to_f * 100.0 ).to_i
							end
						end
					end

					transaction.reference_code = reference_codes.join(',') #capture ids

					if paypal_order.status != 'COMPLETED'

						# @todo need to handle failed response
						transaction.message = paypal_order.error
						transaction.save

						NewRelic::Agent.notice_error( Exception.new("PayPalExpressCheckout Payment Error: #{paypal_order.error}") ) if defined?( NewRelic )
						order.errors.add(:base, :processing_error, message: "Transaction declined.")

					else

						transaction.status = 'approved'
						transaction.save!

						order.payment_status = 'paid'
						order.save!

					end

				else

					transaction.message = "PayPalExpressCheckout Payment Error: response did not include a result"
					transaction.save

					NewRelic::Agent.notice_error( Exception.new("PayPalExpressCheckout Payment Error: response did not include a result") ) if defined?( NewRelic )
					order.errors.add(:base, :processing_error, message: "Paypal failed to authorize your transaction.")

				end


				return transaction
			end

			def provider_name
				@provider_name
			end

			def refund( args = {} )

				# assumes :amount, and :charge_transaction
				charge_transaction	= args.delete( :charge_transaction )
				parent_obj					= args.delete( :order ) || args.delete( :parent )
				charge_transaction	||= Transaction.where( parent_obj: parent_obj ).charge.approved.first if parent_obj.present?
				parent_obj					= charge_transaction.parent_obj

				raise Exception.new('unable to find transaction') if charge_transaction.nil?

				# Generate Refund transaction
				transaction = BazaarCore::Transaction.new( args )
				transaction.status = 'declined'
				transaction.transaction_type	= 'refund'
				transaction.provider			= @provider_name
				transaction.amount				= args[:amount]
				transaction.amount				||= charge_transaction.amount
				transaction.currency			= parent_obj.currency
				transaction.parent_obj			= parent_obj

				if transaction.amount <= 0
					transaction.status = 'declined'
					transaction.errors.add(:base, "Refund amount must be greater than 0")
					return transaction
				end


				request = PayPalCheckoutSdk::Payments::CapturesRefundRequest::new( charge_transaction.reference_code )

				request_body = {
					amount: {
						value: "#{'%.2f' % transaction.amount_as_money}",
						currency_code: transaction.currency.upcase,
					}
				}
				request.request_body(request_body);

				begin

					response = @client.execute(request)
					paypal_refund = response.result

				rescue Exception => e
					# Something went wrong server-side

					execption_message = e.message
					exception_message = e.result.message if e.respond_to? :result

					transaction.message = "PayPalExpressCheckout Refund Error: An Error Occured while executing the refund request. #{exception_message}"
					transaction.save

					NewRelic::Agent.notice_error( e ) if defined?( NewRelic )
					parent_obj.errors.add(:base, :processing_error, message: "An error occured while authorizing the Paypal refund.")

					return transaction

				end


				if paypal_refund.present?

					if paypal_refund.status != 'COMPLETED'

						transaction.status = 'declined'
						transaction.message = "Refund Failed: #{paypal_refund.status}"
						# transaction.errors.add(:base, "Refuned failed")

					else

						transaction.status = 'approved'
						transaction.reference_code = paypal_refund.id

					end
				else

					transaction.status = 'declined'
					transaction.message = 'No response given'

				end

				transaction.save!

				return transaction
			end

			def update_subscription_payment_profile( subscription, args = {} )
				return false
			end


		end
	end
end
