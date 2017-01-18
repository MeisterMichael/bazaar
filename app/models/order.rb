
module SwellEcom
	class Order < ActiveRecord::Base 
		self.table_name = 'orders'

		belongs_to :billing_address, class_name: 'GeoAddress'
		belongs_to :shipping_address, class_name: 'GeoAddress'
		belongs_to :cart
		belongs_to :user

	end
end
