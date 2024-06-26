# Amazon Wallet and Address book with amazon-pay sdk
# https://pay.amazon.com/us/developer/documentation/lpwa/201951060
# https://github.com/amzn/amazon-pay-sdk-ruby

module Bazaar

	module TransactionServices

		class AmazonPayTransactionService < Bazaar::TransactionService
			DEFAULT_PROVIDER_NAME = 'AmazonPay'

			BILLING_AGREEMENT_ADDRESS_XPATH = '/GetBillingAgreementDetailsResponse/GetBillingAgreementDetailsResult/BillingAgreementDetails/Destination/PhysicalDestination'
			BILLING_AGREEMENT_BUYER_XPATH = '/GetBillingAgreementDetailsResponse/GetBillingAgreementDetailsResult/BillingAgreementDetails/Buyer'


			def initialize( args = {} )
				raise Exception.new('add "gem \'amazon_pay\'" to your Gemfile') unless defined?( AmazonPay )

				@store_name = args[:store_name] || ENV['AMAZON_PAY_STORE_NAME']

				@transaction_provider  = args[:transaction_provider]
				raise Exception.new("TransactionProvider not found") unless @transaction_provider.present? || !Bazaar.require_transaction_providers
				@provider_name  = args[:provider_name] || DEFAULT_PROVIDER_NAME

				@sandbox_mode   = Rails.env.development?
				@sandbox_mode   = (ENV['AMAZON_PAY_SANDBOX'] == '1') unless ENV['AMAZON_PAY_SANDBOX'].blank?
				@sandbox_mode   = args[:sandbox] if args.has_key? :sandbox

				@merchant_id  = args[:merchant_id] || ENV['AMAZON_PAY_MERCHANT_ID']
				@access_key   = args[:access_key] || ENV['AMAZON_PAY_ACCESS_KEY']
				@secret_key   = args[:secret_key] || ENV['AMAZON_PAY_SECRET_KEY']
				@client_id   	= args[:client_id] || ENV['AMAZON_PAY_CLIENT_ID']

				@client_options = {}
				@client_options[:region] = args[:region] if args[:region]
				@client_options[:currency_code] = args[:currency_code] if args[:currency_code]
				@client_options[:sandbox] = true if @sandbox_mode

			end

			def capture_payment_method( order, args = {} )
				order.provider = self.provider_name
				order.transaction_provider = self.transaction_provider
				order.merchant_identification = self.merchant_identification
				order.payment_status = 'declined'
				order.save

				log_event( user: order.user, on: order, name: 'error', content: "AmazonPay Payment Profile Error: Unable to process this payment method" )

				order.errors.add(:base, "Unable to process this payment method")
				return false
			end

			def self.custom_escape(val)
				val.to_s.gsub(/([^\w.~-]+)/) do
					'%' + Regexp.last_match(1).unpack('H2' * Regexp.last_match(1).bytesize).join('%').upcase
				end
			end

			def get_login_profile( access_token )
				login = AmazonPay::Login.new(
				  @client_id,
					@client_options
				)

				# The access token is available in the return URL
				# parameters after a user has logged in.
				# access_token

				# Make the 'get_user_info' api call.
				begin
					profile = login.get_login_profile(access_token)
					# name = profile['name']
					# email = profile['email']
					# user_id = profile['user_id']
				rescue Exception => e
					# Invalid access token
					return false
				end

				profile
			end

			def get_client( obj, args = {} )
				return AmazonPay::Client.new(
					ENV['AMAZON_PAY_MERCHANT_ID'],
					ENV['AMAZON_PAY_ACCESS_KEY'],
					ENV['AMAZON_PAY_SECRET_KEY'],
					**@client_options
				)
			end

			def process( order, args = {} )
				args = args.symbolize_keys

				client = get_client( order, args )

				store_name = self.store_name( order, args )
				seller_note = nil #@todo
				seller_capture_note = nil #@todo
				custom_information = order.order_offers.collect{ |order_offer| "#{order_offer.title} x #{order_offer.quantity}" }.join(', ')
				authorization_note = nil #@todo

				# These values are grabbed from the Amazon Pay
				# Address and Wallet widgets
				# args[:address_consent_token], args[:orderReferenceId], args[:amazon_billing_agreement_id]

				order.provider_customer_payment_profile_reference ||= ( args[:orderReferenceId] || args[:billing_agreement_id] )
				order.provider = self.provider_name
				order.transaction_provider = self.transaction_provider
				order.merchant_identification = self.merchant_identification

				transaction = Bazaar::Transaction.create!(
					parent_obj: order,
					provider: provider_name,
					amount: order.total,
					currency: order.currency,
					customer_payment_profile_reference: order.provider_customer_payment_profile_reference,
					status: 'declined',
				)
				order.status = 'failed'
				order.payment_status = 'declined'
				order.save!

				if order.parent.is_a?( Bazaar::Subscription )
					# raise Exception.new('Unable to process subscription rebills')
					billing_agreement_id = order.provider_customer_payment_profile_reference

					# The following API call is not needed at this point, but
					# can be used in the future when you need to validate that
					# the payment method is still valid with the associated billing
					# agreement id.
					res = client.validate_billing_agreement( billing_agreement_id )

					if res.success
						# Set a unique authorization reference id for your
						# first transaction on the billing agreement.
						authorization_reference_id = "#{order.code}-#{transaction.id}-auth"
						capture_reference_id = "#{order.code}-#{transaction.id}-cap"

						# Now you can authorize your first transaction on the
						# billing agreement id. Every month you can make the
						# same API call to continue charging your buyer
						# with the 'capture_now' parameter set to true.
						response = client.authorize_on_billing_agreement(
							billing_agreement_id,
							authorization_reference_id,
							order.total_as_money.to_s,
							currency_code: order.currency.upcase, # Default: USD
							seller_authorization_note: authorization_note,
							transaction_timeout: 0, # Set to 0 for synchronous mode
							capture_now: false, # Set this to true if you want to capture the amount in the same API call
							seller_note: seller_note,
							seller_order_id: order.code,
							store_name: store_name,
							custom_information: custom_information,
						)

						if response.success

							# You will need the Amazon Authorization Id from the
							# AuthorizeOnBillingAgreement API response if you decide
							# to make the Capture API call separately.
							amazon_authorization_id = response.get_element('AuthorizeOnBillingAgreementResponse/AuthorizeOnBillingAgreementResult/AuthorizationDetails','AmazonAuthorizationId')

							# Make the Capture API call if you did not set the
							# 'capture_now' parameter to 'true'. There are
							# additional optional parameters that are not used
							# below.
							response = client.capture(
								amazon_authorization_id,
								capture_reference_id,
								order.total_as_money.to_s,
								currency_code: order.currency.upcase, # Default: USD
								seller_capture_note: seller_capture_note,
							)

							amazon_capture_id = response.get_element('CaptureResponse/CaptureResult/CaptureDetails','AmazonCaptureId')

						else
							transaction.message = "Unable to authorize payment"
							transaction.save
							order.errors.add(:base, :processing_error, message: "Unable to authorize payment.")
						end
					else

						order.errors.add(:base, :processing_error, message: "Billing agreement no longer valid.")
						transaction.message = "Billing agreement no longer valid"
						transaction.save
						return false
					end

				elsif args[:billing_agreement_id].present?

					recurring_order_offer = order.order_offers.select{ |order_offer| order_offer.offer.recurring? }.first

					unless recurring_order_offer.present?
						log_event( user: order.user, on: order, name: 'error', content: "AmazonPay Payment Error: Invalid payment method: Amazon Pay billing agreements are only available for subscriptions purchases." )
						order.errors.add(:base, :processing_error, message: "Invalid payment method: Amazon Pay billing agreements are only available for subscriptions purchases.")
						return false
					end

					subscription = recurring_order_offer.subscription ||= Bazaar::Subscription.create( status: 'trash', user: order.user, offer: recurring_order_offer.offer, shipping_address: order.shipping_address, billing_address: order.billing_address )

					# To get the buyers full address if shipping/tax
					# calculations are needed you can use the following
					# API call to obtain the billing agreement details.
					if args[:address_consent_token].present?
						order_reference_res = client.get_billing_agreement_details(
							args[:billing_agreement_id],
							args[:address_consent_token]
						)
					else
						order_reference_res = client.get_billing_agreement_details(
							args[:billing_agreement_id],
						)
					end

					# Next you will need to set the various details
					# for this subscription with the following API call.
					sbad_res = client.set_billing_agreement_details(
						args[:billing_agreement_id],
						seller_note: seller_note,
						seller_billing_agreement_id: subscription.code,
						store_name: store_name,
						custom_information: custom_information,
					)

					# Make the ConfirmBillingAgreement API call to confirm
					# the Amazon Billing Agreement Id with the details set above.
					# Be sure that everything is set correctly above before
					# confirming.
					cba_res = client.confirm_billing_agreement(
						args[:billing_agreement_id]
					)

					# The following API call is not needed at this point, but
					# can be used in the future when you need to validate that
					# the payment method is still valid with the associated billing
					# agreement id.
					# client.validate_billing_agreement(
					#   args[:billing_agreement_id]
					# )

					# Set a unique authorization reference id for your
					# first transaction on the billing agreement.
					authorization_reference_id = "#{order.code}-#{transaction.id}-auth"
					capture_reference_id = "#{order.code}-#{transaction.id}-cap"

					# Now you can authorize your first transaction on the
					# billing agreement id. Every month you can make the
					# same API call to continue charging your buyer
					# with the 'capture_now' parameter set to true.
					response = client.authorize_on_billing_agreement(
						args[:billing_agreement_id],
						authorization_reference_id,
						order.total_as_money_string,
						currency_code: order.currency.upcase, # Default: USD
						seller_authorization_note: authorization_note,
						transaction_timeout: 0, # Set to 0 for synchronous mode
						capture_now: false, # Set this to true if you want to capture the amount in the same API call
						seller_note: seller_note,
						seller_order_id: order.code,
						store_name: store_name,
						custom_information: custom_information,
					)


					self.set_address_information( order, args )

					if response.success

						# You will need the Amazon Authorization Id from the
						# AuthorizeOnBillingAgreement API response if you decide
						# to make the Capture API call separately.
						amazon_authorization_id = response.get_element('AuthorizeOnBillingAgreementResponse/AuthorizeOnBillingAgreementResult/AuthorizationDetails','AmazonAuthorizationId')

						# Make the Capture API call if you did not set the
						# 'capture_now' parameter to 'true'. There are
						# additional optional parameters that are not used
						# below.
						response = client.capture(
							amazon_authorization_id,
							capture_reference_id,
							order.total_as_money.to_s,
							currency_code: order.currency.upcase, # Default: USD
							seller_capture_note: seller_capture_note,
						)

						amazon_capture_id = response.get_element('CaptureResponse/CaptureResult/CaptureDetails','AmazonCaptureId')

					else
						transaction.message = 'Unable to authorize payment'
						transaction.save
						order.errors.add(:base, :processing_error, message: "Unable to authorize payment.")
					end

				elsif args[:orderReferenceId].present?

					# To get the buyers full address if shipping/tax
					# calculations are needed you can use the following
					# API call to obtain the order reference details.
					order_reference_res = client.get_order_reference_details(
						args[:orderReferenceId],
						address_consent_token: args[:addressConsentToken]
					)

					# self.calculate( order, args )

					# Make the SetOrderReferenceDetails API call to
					# configure the Amazon Order Reference Id.
					client.set_order_reference_details(
						args[:orderReferenceId],
						order.total_as_money.to_s,
						currency_code: order.currency.upcase, # Default: USD
						seller_note: seller_note,
						seller_order_id: order.code,
						store_name: store_name,
					)

					# Make the ConfirmOrderReference API call to
					# confirm the details set in the API call
					# above.
					client.confirm_order_reference(args[:orderReferenceId])

					# Set a unique id for your current authorization
					# of this payment.
					authorization_reference_id = "#{order.code}-#{transaction.id}-auth"
					capture_reference_id = "#{order.code}-#{transaction.id}-cap"

					# Make the Authorize API call to authorize the
					# transaction. You can also capture the amount
					# in this API call or make the Capture API call
					# separately. There are additional optional
					# parameters not used below.
					response = client.authorize(
						args[:orderReferenceId],
						authorization_reference_id,
						order.total_as_money.to_s,
						currency_code: order.currency.upcase, # Default: USD
						seller_authorization_note: authorization_note,
						transaction_timeout: 0, # Set to 0 for synchronous mode
						capture_now: false # Set this to true if you want to capture the amount in the same API call
					)

					if response.success

						amazon_authorization_id = response.get_element('AuthorizeResponse/AuthorizeResult/AuthorizationDetails','AmazonAuthorizationId')

						# Make the Capture API call if you did not set the
						# 'capture_now' parameter to 'true'. There are
						# additional optional parameters that are not used
						# below.
						response = client.capture(
							amazon_authorization_id,
							capture_reference_id,
							order.total_as_money.to_s,
							currency_code: order.currency.upcase, # Default: USD
							seller_capture_note: seller_capture_note,
						)

						amazon_capture_id = response.get_element('CaptureResponse/CaptureResult/CaptureDetails','AmazonCaptureId')

					else
						transaction.message = 'Unable to authorize payment.'
						transaction.save
						order.errors.add(:base, :processing_error, message: "Unable to authorize payment.")
					end

				else
					transaction.message = 'Missing transaction information.'
					transaction.save
					order.errors.add(:base, :processing_error, message: "Missing transaction information.")
					return false
				end

				transaction.amount = order.total
				transaction.reference_code = amazon_capture_id
				# order.provider_reference_code = amazon_capture_id

				transaction.properties['amazon_order_reference_id'] = args[:orderReferenceId]
				transaction.properties['amazon_capture_id'] = amazon_capture_id
				transaction.properties['amazon_authorization_id'] = amazon_authorization_id

				if response.success
					order.payment_status = 'paid'
					order.save

					transaction.status = 'approved'
					transaction.parent_obj = order
				else
					order.status = 'trash'
					order.payment_status = 'declined'
					order.save
					order.errors.add(:base, :processing_error, message: "Transaction declined.")

					transaction.status = 'declined'
					transaction.message = response.get_element('ErrorResponse/Error','Message')
					transaction.message = "Transaction Declined" if transaction.message.blank?
				end

				transaction.save

				transaction
			end

			def provider_name
				@provider_name
			end

			def transaction_provider
				@transaction_provider
			end

			def merchant_identification
				@transaction_provider.try(:merchant_identification)
			end

			def refund( args = {} )

				# assumes :amount, and :charge_transaction
				charge_transaction	= args.delete( :charge_transaction )
				parent_obj					= args.delete( :order ) || args.delete( :parent )
				charge_transaction	||= Transaction.where( parent_obj: parent_obj ).charge.approved.first if parent_obj.present?
				parent_obj					= charge_transaction.parent_obj

				raise Exception.new( "charge_transaction must be an approved charge." ) unless charge_transaction.nil? || ( charge_transaction.charge? && charge_transaction.approved? )

				transaction = Bazaar::Transaction.new( args )
				transaction.transaction_type	= 'refund'
				transaction.provider			    = self.provider_name
				transaction.transaction_provider = self.transaction_provider
				transaction.merchant_identification = self.merchant_identification
				transaction.currency          ||= charge_transaction.currency
				transaction.parent_obj        ||= charge_transaction.parent_obj
				transaction.amount            = charge_transaction.amount unless transaction.amount != 0
				transaction.status            = 'declined'

				transaction.customer_payment_profile_reference ||= charge_transaction.customer_payment_profile_reference

				transaction.save

				client = get_client( transaction, args )
				res = client.refund( charge_transaction.reference_code, transaction.id, transaction.amount_as_money.to_s )


				if res.success

					transaction.status = 'approved'
					transaction.parent_obj.update payment_status: 'refunded'

					transaction.properties['amazon_refund_id'] = get_result_element( res, 'RefundResponse/RefundResult/RefundDetails','AmazonRefundId')
					transaction.reference_code = transaction.properties['amazon_refund_id']

				else

					transaction.status = 'declined'
					transaction.message = get_result_element( res, 'ErrorResponse/Error','Message')

				end

				transaction.save

				transaction
			end

			def set_address_information( order, options )
				# raise Exception.new('set_address_information is incomplete')
				client = get_client( order, options )

				if options[:billing_agreement_id].present?

					# To get the buyers full address if shipping/tax
					# calculations are needed you can use the following
					# API call to obtain the billing agreement details.
					if options[:address_consent_token].present?
						res = client.get_billing_agreement_details(
							options[:billing_agreement_id],
							options[:address_consent_token]
						)
					else
						res = client.get_billing_agreement_details(
							options[:billing_agreement_id],
						)
					end

					customer_name	= (get_result_element(res,BILLING_AGREEMENT_ADDRESS_XPATH,'Name') || "").split(' ', 2) rescue []
					city          = get_result_element(res,BILLING_AGREEMENT_ADDRESS_XPATH,'City')
					state_code    = get_result_element(res,BILLING_AGREEMENT_ADDRESS_XPATH,'StateOrRegion')
					country_code  = get_result_element(res,BILLING_AGREEMENT_ADDRESS_XPATH,'CountryCode')
					postal_code   = get_result_element(res,BILLING_AGREEMENT_ADDRESS_XPATH,'PostalCode')
					phone					= get_result_element(res,BILLING_AGREEMENT_ADDRESS_XPATH,'Phone')
					street				= get_result_element(res,BILLING_AGREEMENT_ADDRESS_XPATH,'AddressLine1')
					street2				= get_result_element(res,BILLING_AGREEMENT_ADDRESS_XPATH,'AddressLine2')

					buyer_email		= get_result_element(res,BILLING_AGREEMENT_BUYER_XPATH,'Email')

					geo_country = GeoCountry.find_by( abbrev: country_code )
					geo_state   = GeoState.find_by( geo_country: geo_country, abbrev: state_code )

					attributes = {}
					attributes[:first_name]		= customer_name.first || 'TBD'
					attributes[:last_name]		= customer_name.last || 'TBD'
					attributes[:phone]				= phone
					attributes[:street]				= street || 'TBD'
					attributes[:street2]			= street2
					attributes[:geo_country]	= geo_country
					attributes[:geo_state]		= geo_state
					attributes[:state]				= state_code unless geo_state.present?
					attributes[:city]					= city
					attributes[:zip]					= postal_code

					order.billing_user_address_attributes = attributes
					order.shipping_user_address_attributes = attributes
					order.shipments.each do |shipment|
						shipment.destination_address = order.shipping_address
						shipment.destination_user_address = order.shipping_user_address
						shipment.save if shipment.persisted?
					end

					order.email ||= buyer_email if buyer_email.present?

				elsif options[:orderReferenceId].present?

					# To get the buyers full address if shipping/tax
					# calculations are needed you can use the following
					# API call to obtain the order reference details.
					if options[:addressConsentToken].present?
						res = client.get_order_reference_details(
							options[:orderReferenceId],
							address_consent_token: options[:address_consent_token]
						)
					else
						res = client.get_order_reference_details(
							options[:orderReferenceId]
						)
					end

				else
					return false
				end

				return true
			end

			def sign_pay_parameters( parameters = {} )
				parameters[:sellerId] ||= @merchant_id
				parameters[:accessKey] ||= @access_key
				parameters[:lwaClientId] ||= @client_id
				parameters[:paymentAction] ||= 'None'
				parameters[:shippingAddressRequired] ||= 'false'
				parameters[:signature] = self.sign_parameters( parameters, host: "payments.amazon.com" )
				parameters[:signature] = self.class.custom_escape( parameters[:signature] )

				parameters
			end

			def validate_pay_signature( signature, parameters, options = {} )
				self.sign_parameters( parameters, options ) == signature
			end

			def sign_parameters( parameters, options = {} )
				options[:method] ||= 'POST'
				options[:path] ||= '/'

				query_parameters = []
				parameters.sort.map.each do |key,value|
					query_parameters += ["#{key}=#{CGI.escape(value).gsub('+','%20')}"]
				end

				str = "#{options[:method]}\n#{options[:host]}\n#{options[:path]}\n#{query_parameters.join('&')}"

				signature = sign_str( str, algorithm: options[:algorithm] )

				if options[:escape] then
					signature = self.class.custom_escape( signature )
				end

				signature
			end

			def sign_str( str, options = {} )
				algorithm = options[:algorithm] || "HmacSHA256"

				if algorithm == 'HmacSHA1'
					hash = 'sha1'
				elsif algorithm == 'HmacSHA256'
					hash = 'sha256'
				else
					raise "Non-supported signing method specified"
				end

				digest = OpenSSL::HMAC.digest(hash, @secret_key, str)

				return Base64.strict_encode64(digest)
			end

			def store_name( order, options = {} )
				@store_name
			end

			def update_subscription_payment_profile( subscription, args = {} )

			end

			protected
			def get_result_element( res, xpath, xml_element )
				xml = res.to_xml
				value = nil
				xml.elements.each(xpath) do |element|
					value = element.elements[xml_element].text if element.elements[xml_element].present?
				end
				return value
			end

		end

	end

end
