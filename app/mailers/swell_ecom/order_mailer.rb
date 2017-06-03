module SwellEcom
	class OrderMailer < ActionMailer::Base
		def receipt( order, args = {} )
			@order = order

			subject = "#{SwellMedia.app_name} order of #{@order.order_items.first.title}".truncate(255)

			mail to: @order.email, from: SwellEcom.order_email_from, subject: subject
		end

	end
end
