module BazaarCore
	class ShippingCarrierService < ApplicationRecord
		

		belongs_to	:shipping_option, required: false
		enum status: { 'inactive' => -1, 'draft' => 0, 'active' => 1 }

	end
end
