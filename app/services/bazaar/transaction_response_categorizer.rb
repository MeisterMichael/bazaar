module Bazaar
	# Maps a payment provider's raw response code to a churn-relevant category.
	# Categories are intentionally coarse so analytics queries and dunning logic
	# can branch on them directly without re-mapping per-provider error tables.
	#
	# Returns one of the symbols listed in CATEGORIES, as a String. Unknown codes
	# return 'unknown'.
	#
	# Usage:
	#   Bazaar::TransactionResponseCategorizer.categorize(
	#     provider: 'Authorize.net BoA',
	#     code: '8',
	#     avs: 'Y', cvv: 'M',
	#   )
	module TransactionResponseCategorizer
		extend self

		CATEGORIES = %w[
			success
			expired_card
			insufficient_funds
			do_not_honor
			lost_or_stolen
			fraud
			cvv_mismatch
			avs_mismatch
			card_velocity_exceeded
			invalid_card
			card_not_accepted
			pickup_card
			account_closed
			duplicate_transaction
			processor_error
			gateway_error
			gateway_timeout
			customer_canceled
			customer_action_needed
			unknown
		].freeze

		# Common Authorize.net error codes mapped to categories. Source:
		# https://developer.authorize.net/api/reference/responseCodes.html
		# Codes not listed fall through to `unknown` and can be added over time.
		AUTHORIZE_NET_CODES = {
			'1'   => 'success',
			'2'   => 'do_not_honor',
			'3'   => 'do_not_honor',
			'4'   => 'pickup_card',
			'6'   => 'expired_card',
			'8'   => 'expired_card',
			'11'  => 'duplicate_transaction',
			'17'  => 'card_not_accepted',
			'19'  => 'processor_error',
			'20'  => 'processor_error',
			'21'  => 'processor_error',
			'22'  => 'processor_error',
			'23'  => 'processor_error',
			'24'  => 'processor_error',
			'25'  => 'processor_error',
			'26'  => 'processor_error',
			'27'  => 'avs_mismatch',
			'28'  => 'card_not_accepted',
			'37'  => 'invalid_card',
			'41'  => 'fraud',
			'44'  => 'cvv_mismatch',
			'45'  => 'customer_action_needed',
			'51'  => 'insufficient_funds',
			'54'  => 'processor_error',
			'65'  => 'cvv_mismatch',
			'78'  => 'cvv_mismatch',
			'200' => 'fraud',
			'201' => 'fraud',
			'202' => 'fraud',
			'203' => 'fraud',
			'204' => 'fraud',
			'205' => 'fraud',
			'206' => 'fraud',
			'207' => 'fraud',
			'PROFILE_CREATION_FAILED' => 'gateway_error',
			'INVALID_AMOUNT' => 'gateway_error',
		}.freeze

		# Amazon Pay V2 reasonCodes from the API plus our own internal codes set
		# in AmazonPayV2TransactionService. The list is augmented over time as
		# previously-unseen codes turn up in production data.
		AMAZON_PAY_V2_CODES = {
			'OK'                       => 'success',
			'Captured'                 => 'success',
			'Authorized'               => 'success',
			'Refunded'                 => 'success',
			'Pending'                  => 'success',
			'Completed'                => 'success',
			'BuyerCanceled'            => 'customer_canceled',
			'CheckoutSessionCanceled'  => 'customer_canceled',
			'Declined'                 => 'do_not_honor',
			'HardDeclined'             => 'do_not_honor',
			'SoftDeclined'             => 'do_not_honor',
			'AmazonRejected'           => 'do_not_honor',
			'ExpiredPaymentMethod'     => 'expired_card',
			'PaymentMethodNotAllowed'  => 'card_not_accepted',
			'PeriodicAmountExceeded'   => 'card_velocity_exceeded',
			'TransactionTimedOut'      => 'gateway_timeout',
			'ServiceUnavailable'       => 'gateway_timeout',
			'ProcessingFailure'        => 'processor_error',
			'InternalServerError'      => 'processor_error',
			'InvalidRequest'           => 'gateway_error',
			'InvalidChargePermissionStatus' => 'gateway_error',
			'InvalidCheckoutSessionStatus'  => 'gateway_error',
			'InvalidParameterValue'    => 'gateway_error',
			'AmountMismatch'           => 'gateway_error',
			'ResourceNotFound'         => 'gateway_error',
			'MISSING_SESSION'          => 'gateway_error',
			'MISSING_CHARGE_PERMISSION' => 'gateway_error',
		}.freeze

		def categorize( provider:, code:, avs: nil, cvv: nil )
			provider = provider.to_s
			code = code.to_s

			# Bare gateway/HTTP failures take precedence over per-provider mapping.
			return 'gateway_error' if code.start_with?('HTTP_')

			# CVV/AVS mismatches are reflected in the result codes themselves,
			# regardless of the gateway's main response code.
			return 'cvv_mismatch' if cvv.present? && cvv.to_s.upcase == 'N'
			return 'avs_mismatch' if avs.present? && %w[N W].include?(avs.to_s.upcase)

			category = if provider.start_with?('Authorize.net')
				AUTHORIZE_NET_CODES[code]
			elsif provider == 'AmazonPayV2'
				AMAZON_PAY_V2_CODES[code]
			end

			category || 'unknown'
		end
	end
end
