# desc "Explaining what the task does"
namespace :swell_ecom do

	task process_payment_method_captured_orders: :environment do

		orders = SwellEcom::Orders.active.payment_method_captured
		orders = orders.where( 'updated_at < ?', 10.minutes.ago )

		order_service = SwellEcom::OrderService.new

		orders.find_each do |order|

			order_service.process( order )

		end

	end

end
