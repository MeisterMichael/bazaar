json.success 						true
json.message						'OK'
json.errors							[]

json.states(@states) do |state|
	json.id			state.id
	json.name		state.name
	json.abbrev		state.abbrev
end
