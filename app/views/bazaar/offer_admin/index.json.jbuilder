json.array!(@offers.to_a) do |offer|
	json.id offer.id
	json.text offer.title_with_price
end