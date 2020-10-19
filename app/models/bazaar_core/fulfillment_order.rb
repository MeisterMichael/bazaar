module BazaarCore
  class FulfillmentOrder < BazaarCore::Order
		include BazaarCore::Concerns::UserAddressAttributesConcern
		include BazaarCore::FulfillmentOrderSearchable if (BazaarCore::FulfillmentOrderSearchable rescue nil)

		belongs_to 	:billing_address, class_name: 'GeoAddress', validate: true, required: false
		belongs_to 	:shipping_address, class_name: 'GeoAddress', validate: true, required: true
		belongs_to 	:billing_user_address, class_name: 'UserAddress', required: false #, validate: true, required: false
		belongs_to 	:shipping_user_address, class_name: 'UserAddress', required: false #, validate: true, required: true

		accepts_nested_attributes_for :shipping_address, :order_items, :order_offers
		accepts_nested_user_address_attributes_for [:shipping_user_address,:shipping_address,:user_id]

  end
end
