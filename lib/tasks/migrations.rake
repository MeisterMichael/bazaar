# desc "Explaining what the task does"
namespace :swell_ecom do
	task migrate_order_status: :environment do

		Order.all.find_each do | order |

			order.payment_status = 'paid' if orders.transaction.positive.present?
			order.payment_status = 'refunded' if orders.transaction.refund.present?
			order.payment_status = 'declinded' if orders.status == -2
			order.payment_status = 'payment_canceled' if orders.status == -3

			order.fulfillment_status = 'fulfilled' if orders.fulfilled_at.present?
			order.fulfillment_status = 'delivered' if orders.status == 2
			order.fulfillment_status = 'fulfillment_canceled' if orders.status == -3
			
			order.save

		end



	end

end
