
$ ->

	$(document).on 'change', '[data-geostateupdate-target]', (event)->
		$select = $(this)
		target = $select.data('geostateupdate-target')
		args = $select.data('geostateupdate-data') || {}
		args['geo_country_id'] = $select.val()

		$.ajax '/checkout/state_input', data: args, success: ( data, status )->
			old_value = $(target).val()
			$(target).replaceWith( $(data).find( target ) )
			$(target).val(old_value)

	$(document).on 'submit', '.disable_submit_after_submit', (event) ->
		# Disable the submit button to prevent repeated clicks:
		$(this).find('.submit').prop 'disabled', true
