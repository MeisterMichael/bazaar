
json.title 				@plan.title

json.avatar 			@plan.avatar

json.description 		@plan.description
json.content			@plan.content

json.price				number_to_currency( @plan.price / 100.to_f )
json.price_in_cents		@plan.price
json.billing_interval	@plan.billing_interval_value.to_s + " " + @plan.billing_interval_unit

json.trial_interval 	@plan.trial_interval_value.to_s + " " + @plan.trial_interval_unit
