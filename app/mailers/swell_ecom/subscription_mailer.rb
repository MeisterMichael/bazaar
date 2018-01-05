module SwellEcom
	class SubscriptionMailer < ActionMailer::Base

		def payment_profile_expiration_reminder( subscription )
			@subscription = subscription
			subject = "Your payment information is about to expire"
			mail to: @subscription.user.email, from: SwellEcom.order_email_from, subject: subject
		end

	end
end
