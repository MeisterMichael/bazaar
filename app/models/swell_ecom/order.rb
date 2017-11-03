
module SwellEcom
	class Order < ActiveRecord::Base
		self.table_name = 'orders'

		enum status: { 'declined' => -2, 'refunded' => -1, 'placed' => 0, 'fulfilled' => 1, 'delivered' => 2 }

		before_create :generate_order_code


		belongs_to 	:billing_address, class_name: 'GeoAddress'
		belongs_to 	:shipping_address, class_name: 'GeoAddress'
		belongs_to 	:user

		has_many 	:order_items, dependent: :destroy

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
