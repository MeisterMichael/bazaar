json.array!(@offers) do |offer|
	json.id offer.id
	json.text offer.title
end