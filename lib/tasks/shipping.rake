
namespace :bazaar do

	# desc "Fetches and updates delivery status for all fulfilled orders"
	task shipping_sync: :environment do
		shipping_service = Bazaar.shipping_service_class.constantize.new( Bazaar.shipping_service_config )

		Bazaar::CheckoutOrder.fulfilled.where.not( tracking_number: nil ).find_each do | order |
			delivery_status = shipping_service.fetch_delivery_status( order )

			if delivery_status && delivery_status[:delivered_at].present?
				order.fulfillment_status = 'delivered'
				order.delivered_at = delivery_status[:delivered_at]
			end
		end
	end
end
