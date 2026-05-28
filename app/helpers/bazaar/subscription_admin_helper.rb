module Bazaar
	module SubscriptionAdminHelper

		# Returns true if the subscription is currently in a customer-initiated
		# pause. A paused subscription retains status='active' but stores pause
		# metadata in its properties hash. The pause is "current" only while
		# properties['paused_until'] is a future timestamp.
		def subscription_paused?( subscription )
			return false unless subscription.respond_to?(:properties) && subscription.properties.is_a?(Hash)
			return false if subscription.properties['paused_until'].blank?
			Time.parse( subscription.properties['paused_until'].to_s ) > Time.now
		rescue ArgumentError, TypeError
			false
		end

		# Returns the Time at which the pause ends, or nil if not paused.
		def subscription_pause_ends_at( subscription )
			return nil unless subscription_paused?( subscription )
			Time.parse( subscription.properties['paused_until'].to_s )
		rescue ArgumentError, TypeError
			nil
		end

		# Returns the Time at which the pause was initiated, or nil if missing.
		def subscription_paused_at( subscription )
			return nil unless subscription_paused?( subscription )
			value = subscription.properties['paused_at']
			return nil if value.blank?
			Time.parse( value.to_s )
		rescue ArgumentError, TypeError
			nil
		end

		# Returns the duration (in months) the customer originally selected
		# when initiating the pause, or nil if missing.
		def subscription_pause_duration_months( subscription )
			return nil unless subscription_paused?( subscription )
			value = subscription.properties['pause_duration_months']
			return nil if value.blank?
			value.to_i
		end

		# Computes the next_charged_at that an unpause action would set
		# RIGHT NOW. Mirrors the logic in Settings::SubscriptionsController#resume
		# and Bazaar::SubscriptionAdminController#unpause:
		#   max(pre_pause_next_charged_at, tomorrow.beginning_of_day)
		# Used by the admin edit view to preview the resume date in the banner.
		def subscription_unpause_next_charged_at( subscription )
			return nil unless subscription_paused?( subscription )

			tomorrow = ( Time.now + 1.day ).beginning_of_day
			pre_pause_date = begin
				Time.parse( subscription.properties['pre_pause_next_charged_at'].to_s )
			rescue ArgumentError, TypeError
				nil
			end

			[pre_pause_date, tomorrow].compact.max
		end

	end
end
