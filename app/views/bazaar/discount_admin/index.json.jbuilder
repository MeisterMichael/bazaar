json.array!(@discounts.to_a) do |discount|
	json.id discount.id
	json.text discount.title
end