json.success 						true
json.message						'OK'
json.errors							[]

json.subtotal						@order.subtotal || 0
json.discounts						@order.discount || 0
json.taxes 							@order.tax || 0
json.shipping 						@order.shipping || 0
json.total							@order.total || 0

json.shipping_options(@order.shipments.to_a.collect(&:rates).flatten) do |shipping_rate|
	json.label		shipping_rate[:label]
	json.name		shipping_rate[:carrier_service].name
	json.id			shipping_rate[:id]
	json.code		shipping_rate[:carrier_service].service_code
	json.price		shipping_rate[:price]
end
