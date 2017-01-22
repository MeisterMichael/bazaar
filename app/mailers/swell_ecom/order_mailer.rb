module SwellEcom
	class OrderMailer < ActionMailer::Base
		def receipt( order, args = {} )
			@order = order

			mail to: @order.email, from: SwellEcom.order_email_from, subject: "#{SwellMedia.app_name} order of #{@order.list_items.first.label}".truncate(255)
		end

	end
end
