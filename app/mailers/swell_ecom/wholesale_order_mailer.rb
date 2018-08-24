module SwellEcom
	class WholesaleOrderMailer < ActionMailer::Base

		def notify_admin( order )
			@order = order
			subject = "#{SwellMedia.app_name} order of #{@order.order_items.first.title}".truncate(255)
			mail to: "gk@amraplife.com", from: SwellEcom.order_email_from, subject: subject
		end

		def receipt( order, args = {} )
			@order = order

			subject = "#{SwellMedia.app_name} order of #{@order.order_items.first.title}".truncate(255)

			mail to: @order.email, from: SwellEcom.order_email_from, subject: subject
		end

		def refund( transaction, args = {} )
			@transaction = transaction

			subject = "#{SwellMedia.app_name} refund".truncate(255)

			email = transaction.parent_obj.email || transaction.parent_obj.user.try(:email)

			mail to: email, from: SwellEcom.order_email_from, subject: subject
		end

	end
end
