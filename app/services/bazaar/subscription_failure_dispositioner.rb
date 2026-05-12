module Bazaar
	# Maps a failed transaction's normalized response (provider + code + category)
	# to a subscription-level disposition: what kind of failure is this, and what
	# can be done about it?
	#
	# Inputs are produced by Bazaar::TransactionResponseCategorizer (`category`)
	# and the raw provider response (`code`, `provider`). Outputs are the
	# Bazaar::Subscription `failed_reason` and `failed_recovery_action` enum
	# values as symbols.
	#
	# Usage:
	#   reason, action = Bazaar::SubscriptionFailureDispositioner.disposition(
	#     category: 'gateway_error',
	#     code:     'InvalidChargePermissionStatus',
	#     provider: 'AmazonPayV2',
	#   )
	#   # => [:provider_authorization_revoked, :reauthorize_provider]
	module SubscriptionFailureDispositioner
		extend self

		# Amazon Pay V2 codes that indicate the ChargePermission / CheckoutSession
		# has been closed or is otherwise unusable. No amount of retrying recovers
		# these — the customer has to re-authorize via the Amazon Pay flow.
		AMAZON_REVOKED_CODES = %w[
			InvalidChargePermissionStatus
			InvalidCheckoutSessionStatus
			MISSING_CHARGE_PERMISSION
		].freeze

		# Amazon Pay V2 explicitly tells us not to retry.
		AMAZON_HARD_DECLINE_CODES = %w[HardDeclined].freeze

		# Authorize.net response codes that the categorizer leaves as 'unknown'
		# but for which we have a confident subscription-level disposition.
		AUTHNET_UNKNOWN_CODE_DISPOSITIONS = {
			'E00040' => [:payment_method_invalidated, :update_credit_card],   # Customer Profile / Payment Profile not found
			'252'    => [:card_flagged,               :terminal_no_action],   # Held for review (fraud)
			'E00104' => [:transient_retrying,         :none_required],        # Server in maintenance
		}.freeze

		DEFAULT = [:unknown_reason, :contact_support].freeze

		# Returns [failed_reason_symbol, failed_recovery_action_symbol].
		def disposition(category:, code: nil, provider: nil)
			category = category.to_s
			code     = code.to_s
			provider = provider.to_s

			case category
			when 'do_not_honor'
				if AMAZON_HARD_DECLINE_CODES.include?(code)
					[:provider_authorization_revoked, :reauthorize_provider]
				else
					[:transient_retrying, :none_required]
				end

			when 'gateway_error'
				if AMAZON_REVOKED_CODES.include?(code)
					[:provider_authorization_revoked, :reauthorize_provider]
				else
					[:transient_retrying, :none_required]
				end

			when 'customer_canceled'
				[:provider_authorization_revoked, :reauthorize_provider]

			when 'expired_card', 'invalid_card', 'card_not_accepted', 'customer_action_needed'
				[:user_action_required, :update_credit_card]

			when 'avs_mismatch'
				[:user_action_required, :verify_billing_address]

			when 'cvv_mismatch'
				[:user_action_required, :verify_security_code]

			when 'insufficient_funds', 'card_velocity_exceeded', 'duplicate_transaction', 'gateway_timeout', 'processor_error'
				[:transient_retrying, :none_required]

			when 'pickup_card', 'fraud'
				[:card_flagged, :terminal_no_action]

			when 'account_closed'
				[:payment_method_invalidated, :update_credit_card]

			when 'unknown'
				AUTHNET_UNKNOWN_CODE_DISPOSITIONS[code] || DEFAULT

			else
				# nil/empty/'success' (success on a failed row shouldn't happen) or
				# any new category the categorizer adds later — fall through safely.
				DEFAULT
			end
		end
	end
end
