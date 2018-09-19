json.success 						true
json.message						'OK'
json.errors							[]
json.total_count					@plans.total_count
json.count							@plans.count

json.results(@plans) do |product|
	json.title		product.title
	json.id			product.id
end
