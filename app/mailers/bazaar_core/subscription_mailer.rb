module Bazaar
	class SubscriptionMailer < ActionMailer::Base

		def payment_profile_expiration_reminder( subscription )
			@subscription = subscription
			subject = "Your payment information is about to expire"
			mail to: @subscription.user.email, from: Bazaar.order_email_from, subject: subject
		end

		def renewal_failure( subscription )
			@subscription = subscription
			subject = "Your subscription renewal failed"
			mail to: @subscription.user.email, from: Bazaar.order_email_from, subject: subject
		end

	end
end
