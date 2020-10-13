
module Bazaar
	class CheckoutOrder < Bazaar::Order
		include Bazaar::Concerns::UserAddressAttributesConcern
		include Bazaar::CheckoutOrderSearchable if (Bazaar::CheckoutOrderSearchable rescue nil)

		belongs_to 	:billing_address, class_name: 'GeoAddress', validate: true, required: true
		belongs_to 	:shipping_address, class_name: 'GeoAddress', validate: true, required: true
		belongs_to 	:billing_user_address, class_name: 'UserAddress', required: false #, validate: true, required: true
		belongs_to 	:shipping_user_address, class_name: 'UserAddress', required: false #, validate: true, required: true

		accepts_nested_attributes_for :billing_address, :shipping_address, :order_items, :order_offers, :transactions
		accepts_nested_user_address_attributes_for [:billing_user_address,:billing_address,:user_id], [:shipping_user_address,:shipping_address,:user_id]

	end
end
