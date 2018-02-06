# desc "Explaining what the task does"
namespace :swell_ecom do
	task migrate_order_status: :environment do

		orders = SwellEcom::Order.all
		orders.find_each do |order|

			order.payment_status = 'paid' if order.transactions.positive.present?
			order.payment_status = 'refunded' if order.transactions.refund.present?
			order.payment_status = 'declinded' if order[:status] == -2
			order.payment_status = 'payment_canceled' if order[:status] == -3

			order.fulfillment_status = 'fulfilled' if order.fulfilled_at.present?
			order.fulfillment_status = 'delivered' if order[:status] == 2
			order.fulfillment_status = 'fulfillment_canceled' if order[:status] == -3

			order.status = 'active'

			order.save
		end

	end

end
