
module Bazaar
	class WholesaleOrder < Bazaar::Order
		include Bazaar::WholesaleOrderSearchable if (Bazaar::WholesaleOrderSearchable rescue nil)

		belongs_to 	:billing_address, class_name: 'GeoAddress', validate: true, required: true
		belongs_to 	:shipping_address, class_name: 'GeoAddress', validate: true, required: true

		accepts_nested_attributes_for :billing_address, :shipping_address, :order_items

	end
end
