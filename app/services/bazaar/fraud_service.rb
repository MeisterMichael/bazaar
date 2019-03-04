module Bazaar

	class FraudService < ::ApplicationService

		def initialize( options = {} )
			@options = options
		end

		def fraud?( order )
			return false
		end

		def suspicious?( order )
			return false
		end

		def accept_review( order )
			return false unless order.review?

			order.active!

			order.order_items.where.not( subscription: nil ).each do |order_item|
				order_item.subscription.active! if order_item.subscription.review?
			end

			order.order_items.prod.where( item_type: Bazaar::Subscription.base_class.name ).each do |order_item|
				order_item.item.active! if order_item.item.review?
			end

			order.shipments.each do |shipment|
				shipment.pending! if shipment.item.review?
			end


			return true
		end


		def hold_for_review( order )

			order.hold_review!

			order.order_items.prod.where.not( subscription: nil ).each do |order_item|
				order_item.subscription.hold_review! if order_item.subscription.active?
			end

			order.shipments.each do |shipment|
				shipment.hold_review!
			end

		end

		def mark_for_review( order )

			order.review!

			order.order_items.prod.where.not( subscription: nil ).each do |order_item|
				order_item.subscription.review! if order_item.subscription.active?
			end

			order.shipments.each do |shipment|
				shipment.review! if shipment.pending?
			end

		end

		def post_processing( order )
			mark_for_review( order ) if suspicious?( order )
		end

		def reject_review( order )
			return false unless order.review?

			order.rejected!

			order.order_items.where.not( subscription: nil ).each do |order_item|
				order_item.subscription.rejected!
			end

			order.order_items.prod.where( item_type: Bazaar::Subscription.base_class.name ).each do |order_item|
				order_item.item.rejected!
			end

			order.shipments.each do |shipment|
				shipment.rejected!
			end

			return true

		end

		def validate( order )
			if self.fraud?( order )
				log_event( user: order.user, name: 'error', on: order, content: "this order is suspected of fraud." )
				order.errors.add( :base, :processing_error, message: 'We are unable to process your order, please contact support for assistance.' )
			end
		end

	end

end
