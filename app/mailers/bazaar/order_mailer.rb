module Bazaar
	class OrderMailer < ActionMailer::Base

		def notify_admin( order )
			@order = order
			subject = "#{SwellMedia.app_name} order of #{@order.order_offers.first.title}".truncate(255)
			mail to: "gk@amraplife.com", from: Bazaar.order_email_from, subject: subject
		end

		def receipt( order, args = {} )
			@order = order

			subject = "#{Pulitzer.app_name} order of #{@order.order_offers.first.title}".truncate(255)

			mail to: @order.email, from: Bazaar.order_email_from, subject: subject
		end

		def refund( transaction, args = {} )
			@transaction = transaction

			subject = "#{Pulitzer.app_name} refund".truncate(255)

			email = transaction.parent_obj.email || transaction.parent_obj.user.try(:email)

			mail to: email, from: Bazaar.order_email_from, subject: subject
		end

		def hold_for_review( order )
			@order = order

			subject = "Your order is being reviewed"

			mail to: @order.email, from: Bazaar.order_email_from, subject: subject
		end

	end
end
