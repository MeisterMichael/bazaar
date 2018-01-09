
module SwellEcom
	class Order < ActiveRecord::Base
		self.table_name = 'orders'

		enum payment_status: { 'payment_canceled' => -3, 'declined' => -2, 'refunded' => -1, 'pending' => 0, 'paid' => 1 }
		enum fulfillment_status: { 'fulfillment_canceled' => -3, 'unfulfilled' => 0, 'fulfilled' => 1, 'recieved' => 2 }
		enum generated_by: { 'customer_generated' => 1, 'system_generaged' => 2 }

		before_create :generate_order_code


		belongs_to 	:billing_address, class_name: 'GeoAddress', validate: true
		belongs_to 	:shipping_address, class_name: 'GeoAddress', validate: true
		belongs_to 	:user
		belongs_to	:parent, polymorphic: true

		has_many 	:order_items, dependent: :destroy, validate: true
		has_many	:transactions, as: :parent_obj

		has_one 	:cart, dependent: :destroy


		private

		def generate_order_code
			self.code = loop do
  				token = SecureRandom.urlsafe_base64( 6 )
  				break token unless Order.exists?( code: token )
			end
		end

	end
end
