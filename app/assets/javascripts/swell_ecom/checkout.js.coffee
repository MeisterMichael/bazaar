
$ ->

	$(document).on 'change', '[data-geostateupdate-target]', (event)->
		console.log 'geostateupdate', event
		$select = $(this)
		target = $select.data('geostateupdate-target')
		args = $select.data('geostateupdate-data') || {}
		args['geo_country_id'] = $select.val()
		console.log 'geostateupdate', args
		$.ajax '/checkout/state_input', data: args, success: ( data, status )->
			console.log 'replace', target, $(target)[0], $(data).find( target )[0]
			old_value = $(target).val()
			$(target).replaceWith( $(data).find( target ) )
			$(target).val(old_value)

	$(document).on 'submit', '.disable_submit_after_submit', (event) ->
		# Disable the submit button to prevent repeated clicks:
		$(this).find('.submit').prop 'disabled', true
