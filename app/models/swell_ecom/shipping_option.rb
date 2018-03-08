module SwellEcom
	class ShippingOption < ActiveRecord::Base
		self.table_name = 'shipping_options'

		has_many	:shipping_carrier_services
		enum status: { 'trash' => -2, 'inactive' => -1, 'draft' => 0, 'active' => 1 }

	end
end
