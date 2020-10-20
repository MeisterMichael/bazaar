json.success 						true
json.message						'OK'
json.errors							[]
json.total_count					@products.total_count
json.count							@products.count

json.results(@products) do |product|
	json.title		product.title
	json.id			product.id
end
