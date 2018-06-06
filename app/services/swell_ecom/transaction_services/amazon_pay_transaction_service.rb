# Amazon Wallet and Address book with amazon-pay sdk
# https://pay.amazon.com/us/developer/documentation/lpwa/201951060
# https://github.com/amzn/amazon-pay-sdk-ruby

module SwellEcom

	module TransactionServices

		class AmazonPayTransactionService < SwellEcom::TransactionService
			DEFAULT_PROVIDER_NAME = 'AmazonPay'

			def initialize( args = {} )
				raise Exception.new('add "gem \'amazon_pay\'" to your Gemfile') unless defined?( AmazonPay )

        @store_name = args[:store_name]

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

      # def calculate_order( order, options = {} )
      #   set_address_information( order, options )
      #   super(order, options)
      # end

			def capture_payment_method( order, args = {} )

			end

	    def self.custom_escape(val)
	      val.to_s.gsub(/([^\w.~-]+)/) do
	        '%' + Regexp.last_match(1).unpack('H2' * Regexp.last_match(1).bytesize).join('%').upcase
	      end
	    end

      def get_client( obj, args = {} )
        return AmazonPay::Client.new(
          @merchant_id,
          @access_key,
          @secret_key,
          @client_options
        )
      end

			def process( order, args = {} )
				args = args.symbolize_keys

        client = get_client( order, args )

        store_name = self.store_name( order, args )
        seller_note = nil #@todo
        seller_capture_note = nil #@todo
        custom_information = nil #@todo
        authorization_note = nil #@todo

        # These values are grabbed from the Amazon Pay
        # Address and Wallet widgets
        # args[:address_consent_token], args[:orderReferenceId], args[:amazon_billing_agreement_id]

        order.provider_customer_payment_profile_reference ||= ( args[:orderReferenceId] || args[:amazon_billing_agreement_id] )

        transaction = SwellEcom::Transaction.new(
          provider: provider_name,
          amount: order.total,
          currency: order.currency,
          customer_payment_profile_reference: order.provider_customer_payment_profile_reference,
          status: 'declined',
        )
        transaction.parent_obj ||= args[:default_parent_obj]
        transaction.parent_obj ||= order.user if order.user.persisted?

        order.status = 'draft'
        order.payment_status = 'declined'

        if order.parent.is_a?( SwellEcom::Subscription )
					raise Exception.new('Unable to process subscription rebills')

          # The following API call is not needed at this point, but
          # can be used in the future when you need to validate that
          # the payment method is still valid with the associated billing
          # agreement id.
          res = client.validate_billing_agreement(
            order.provider_customer_payment_profile_reference
          )

          if res.success
            # Set a unique authorization reference id for your
            # first transaction on the billing agreement.
            transaction.save!
            authorization_reference_id = transaction.id

            # Now you can authorize your first transaction on the
            # billing agreement id. Every month you can make the
            # same API call to continue charging your buyer
            # with the 'capture_now' parameter set to true.
            order.save
            client.authorize_on_billing_agreement(
              args[:amazon_billing_agreement_id],
              authorization_reference_id,
              order.total_as_money.to_s,
              currency_code: order.currency.upcase, # Default: USD
              seller_authorization_note: authorization_note,
              transaction_timeout: 0, # Set to 0 for synchronous mode
              capture_now: true, # Set this to true if you want to capture the amount in the same API call
              seller_note: seller_note,
              seller_order_id: order.code,
              store_name: store_name,
              custom_information: custom_information,
            )

            # You will need the Amazon Authorization Id from the
            # AuthorizeOnBillingAgreement API response if you decide
            # to make the Capture API call separately.
            amazon_authorization_id = res.get_element('AuthorizeOnBillingAgreementResponse/AuthorizeOnBillingAgreementResult/AuthorizationDetails','AmazonAuthorizationId')

          else

            transaction.message = "Billing agreement no longer valid"

          end

        elsif args[:amazon_billing_agreement_id].present?
					raise Exception.new('Unable to process subscriptions')

          # To get the buyers full address if shipping/tax
          # calculations are needed you can use the following
          # API call to obtain the billing agreement details.
          order_reference_res = client.get_billing_agreement_details(
            args[:amazon_billing_agreement_id],
            args[:address_consent_token]
          )

  	      # self.calculate( order, args )

          # Next you will need to set the various details
          # for this subscription with the following API call.
          client.set_billing_agreement_details(
            args[:amazon_billing_agreement_id],
            seller_note: seller_note,
            seller_billing_agreement_id: @subscription.code,
            store_name: store_name,
            custom_information: custom_information,
          )

          # Make the ConfirmBillingAgreement API call to confirm
          # the Amazon Billing Agreement Id with the details set above.
          # Be sure that everything is set correctly above before
          # confirming.
          client.confirm_billing_agreement(
            args[:amazon_billing_agreement_id]
          )

          # The following API call is not needed at this point, but
          # can be used in the future when you need to validate that
          # the payment method is still valid with the associated billing
          # agreement id.
          # client.validate_billing_agreement(
          #   args[:amazon_billing_agreement_id]
          # )

          # Set a unique authorization reference id for your
          # first transaction on the billing agreement.
          transaction.save!
          authorization_reference_id = transaction.id

          # Now you can authorize your first transaction on the
          # billing agreement id. Every month you can make the
          # same API call to continue charging your buyer
          # with the 'capture_now' parameter set to true.
          order.save
          client.authorize_on_billing_agreement(
            args[:amazon_billing_agreement_id],
            authorization_reference_id,
            order.total_as_money.to_s,
            currency_code: order.currency.upcase, # Default: USD
            seller_authorization_note: authorization_note,
            transaction_timeout: 0, # Set to 0 for synchronous mode
            capture_now: true, # Set this to true if you want to capture the amount in the same API call
            seller_note: seller_note,
            seller_order_id: order.code,
            store_name: store_name,
            custom_information: custom_information,
          )

          # You will need the Amazon Authorization Id from the
          # AuthorizeOnBillingAgreement API response if you decide
          # to make the Capture API call separately.
          amazon_authorization_id = res.get_element('AuthorizeOnBillingAgreementResponse/AuthorizeOnBillingAgreementResult/AuthorizationDetails','AmazonAuthorizationId')

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
          order.save
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
          transaction.save!
          authorization_reference_id = "#{transaction.id}-a"
					capture_reference_id = "#{transaction.id}-c"

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

					end

        else
          order.status = 'active'
          order.errors.add(:base, :processing_error, message: "Missing transaction information.")
          return false
        end

        transaction.amount = order.total
        transaction.reference_code = amazon_capture_id

				transaction.properties['amazon_order_reference_id'] = args[:orderReferenceId]
				transaction.properties['amazon_capture_id'] = amazon_capture_id
				transaction.properties['amazon_authorization_id'] = amazon_authorization_id

        if response.success
      		order.status = 'active'
          order.payment_status = 'paid'
          order.save

          transaction.status = 'approved'
          transaction.parent_obj = order
        else
					order.status = 'trash'
          order.payment_status = 'declined'
          order.save if order.persisted?
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

			def refund( args = {} )

        # assumes :amount, and :charge_transaction
        charge_transaction	= args.delete( :charge_transaction )
        parent				= args.delete( :order ) || args.delete( :parent )
        charge_transaction	||= Transaction.where( parent_obj: parent ).charge.first if parent.present?

        raise Exception.new( "charge_transaction must be an approved charge." ) unless charge_transaction.nil? || ( charge_transaction.charge? && charge_transaction.approved? )

        transaction = SwellEcom::Transaction.new( args )
        transaction.transaction_type	= 'refund'
        transaction.provider			    = self.provider_name
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

					transaction.properties['amazon_refund_id'] = res.get_element('RefundResponse/RefundResult/RefundDetails','AmazonRefundId')
					transaction.reference_code = transaction.properties['amazon_refund_id']

        else

          transaction.status = 'declined'
          transaction.message = res.get_element('ErrorResponse/Error','Message')

        end

        transaction.save

        transaction
			end

      def set_address_information( order, options )
				raise Exception.new('set_address_information is incomplete')
        client = get_client( order, args )

        if options[:amazon_billing_agreement_id].present?

          # To get the buyers full address if shipping/tax
          # calculations are needed you can use the following
          # API call to obtain the billing agreement details.
          if options[:address_consent_token].present?
            res = client.get_billing_agreement_details(
              options[:amazon_billing_agreement_id],
              options[:address_consent_token]
            )
          else
            res = client.get_billing_agreement_details(
              options[:amazon_billing_agreement_id],
            )
          end

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

					# puts res.to_xml

        else
          return false
        end

        # @todo extract billing/shipping addresses from res

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

		end

	end

end
