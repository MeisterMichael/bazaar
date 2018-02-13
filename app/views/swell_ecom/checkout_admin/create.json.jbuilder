json.success 						@order.errors.blank?
json.message						@message
json.errors							@order.errors.to_a

json.order_code						@order.code
json.email 							@order.email

json.billing_address_first_name 	@order.billing_address.first_name
json.billing_address_last_name		@order.billing_address.last_name
json.billing_address_street 		@order.billing_address.street
json.billing_address_street2 		@order.billing_address.street2
json.billing_address_city 			@order.billing_address.city
json.billing_address_state 			@order.billing_address.geo_state.try(:abbrev)
json.billing_address_zip 			@order.billing_address.zip

json.shipping_address_first_name 	@order.shipping_address.first_name
json.shipping_address_last_name		@order.shipping_address.last_name
json.shipping_address_street 		@order.shipping_address.street
json.shipping_address_street2 		@order.shipping_address.street2
json.shipping_address_city 			@order.shipping_address.city
json.shipping_address_state 		@order.shipping_address.geo_state.try(:abbrev)
json.shipping_address_zip 			@order.shipping_address.zip
