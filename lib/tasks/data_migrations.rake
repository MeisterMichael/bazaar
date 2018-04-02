# desc "Explaining what the task does"
namespace :swell_ecom do

	task backfill_geo_address_tags: :environment do

		SwellEcom::GeoAddress.where( id: SwellEcom::Order.select(:shipping_address_id) ).find_each do |geo_address|
			geo_address.tags = geo_address.tags + ['shipping_address']
			geo_address.save

			geo_address.user.update( preferred_shipping_address_id: geo_address.id ) if geo_address.user
		end

		SwellEcom::GeoAddress.where( id: SwellEcom::Order.select(:billing_address_id) ).find_each do |geo_address|
			geo_address.tags = geo_address.tags + ['billing_address']
			geo_address.save

			geo_address.user.update( preferred_billing_address_id: geo_address.id ) if geo_address.user
		end

	end

	task migrate_all_orders_to_checkout_order: :environment do

		orders = SwellEcom::Order.all
		orders.update_all( type: SwellEcom.checkout_order_class_name, source: 'Consumer Checkout' )

	end

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
