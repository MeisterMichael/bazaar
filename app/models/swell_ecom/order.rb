
module SwellEcom
	class Order < ActiveRecord::Base
		self.table_name = 'orders'

		enum payment_status: { 'payment_canceled' => -3, 'declined' => -2, 'refunded' => -1, 'pending' => 0, 'partially_paid' => 1, 'paid' => 2 }
		enum fulfillment_status: { 'fulfillment_canceled' => -3, 'fulfillment_error' => -1, 'unfulfilled' => 0, 'partially_fulfulled' => 1, 'fulfilled' => 2, 'delivered' => 3 }
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
				token = "#{SwellEcom.order_code_prefix}#{token}"if SwellEcom.order_code_prefix.present?
				token = "#{token}#{SwellEcom.order_code_postfix}"if SwellEcom.order_code_postfix.present?
  				break token unless Order.exists?( code: token )
			end
		end

	end
end
