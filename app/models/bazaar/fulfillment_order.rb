module Bazaar
  class FulfillmentOrder < Bazaar::Order
		include Bazaar::FulfillmentOrderSearchable if (Bazaar::FulfillmentOrderSearchable rescue nil)

		belongs_to 	:billing_address, class_name: 'GeoAddress', validate: true, required: false
		belongs_to 	:shipping_address, class_name: 'GeoAddress', validate: true, required: true

		accepts_nested_attributes_for :shipping_address, :order_items, :order_offers

  end
end
