# desc "Explaining what the task does"
namespace :bazaar do

	task process_payment_method_captured_orders: :environment do

		orders = Bazaar.checkout_order_class_name.constantize.active.payment_method_captured
		orders = orders.where( 'updated_at < ?', 10.minutes.ago )

		order_service = Bazaar::OrderService.new

		orders.find_each do |order|

			order_service.process( order )

		end

	end

end
