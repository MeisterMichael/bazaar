# desc "Explaining what the task does"
namespace :swell_ecom do

		task recalculate_order_rollups: :environment do

			orders = SwellEcom::Order.all
			orders.find_each do |order|

				order.shipping = order.order_items.select(&:shipping?).sum(&:subtotal)
				order.tax = order.order_items.select(&:tax?).sum(&:subtotal)
				order.subtotal = order.order_items.select(&:prod?).sum(&:subtotal)
				order.discount = order.order_items.select(&:discount?).sum(&:subtotal)
				order.save

			end

		end


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

	task migrate_subscription_customizations: :environment do
		subscriptions = SwellEcom::Subscription.all

		subscriptions.find_each do |subscription|

			subscription.billing_interval_value	= subscription.subscription_plan.billing_interval_value
			subscription.billing_interval_unit	= subscription.subscription_plan.billing_interval_unit
			subscription.trial_price			= subscription.trial_amount / subscription.quantity
			subscription.price					= subscription.amount / subscription.quantity
			subscription.save!

		end
	end

end
