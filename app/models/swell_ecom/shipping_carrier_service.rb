module SwellEcom
	class ShippingCarrierService < ActiveRecord::Base
		self.table_name = 'shipping_carrier_services'

		belongs_to	:shipping_option, required: false
		enum status: { 'inactive' => -1, 'draft' => 0, 'active' => 1 }

	end
end
