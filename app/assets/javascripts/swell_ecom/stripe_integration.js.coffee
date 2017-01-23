$ ->

	$('.disable_submit_after_submit').submit (event) ->
		# Disable the submit button to prevent repeated clicks:
		$(this).find('.submit').prop 'disabled', true

	$('.stripe_form').each ->
		$form = $(this)

		stripeResponseHandler = (status, response) ->
			console.log response
			if response.error
				# Problem!
				# Show the errors on the form:
				$form.find('.payment-errors').text response.error.message
				$form.find('.submit').prop 'disabled', false
				# Re-enable submission
			else
				# Token was created!
				# Get the token ID:
				token = response.id
				# Insert the token ID into the form so it gets submitted to the server:
				$form.append $('<input type="hidden" name="stripeToken">').val(token)
				# Submit the form:
				$form.get(0).submit();
			return

		$form.submit (event) ->
			# Disable the submit button to prevent repeated clicks:
			$form.find('.submit').prop 'disabled', true
			# Request a token from Stripe:
			Stripe.card.createToken $form, stripeResponseHandler
			# Prevent the form from being submitted:
			false