json.success 						true
json.message						'OK'
json.errors							[]

json.subtotal						@order.order_items.select(&:prod?).sum(&:subtotal)
json.discounts						@order.order_items.select(&:discount?).sum(&:subtotal)
json.taxes 							@order.order_items.select(&:tax?).sum(&:subtotal)
json.shipping 						@order.order_items.select(&:shipping?).sum(&:subtotal)
json.total							@order.total || 0

json.shipping_options(@shipping_rates) do |shipping_rate|
	json.name		shipping_rate[:name]
	json.code		shipping_rate[:code]
	json.price		shipping_rate[:price]
end
