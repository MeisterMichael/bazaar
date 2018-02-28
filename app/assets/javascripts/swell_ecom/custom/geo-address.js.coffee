
$ ->

	$('.geo-address-country-state-group').each ->
		$group = $(this)
		options = $group.data()
		$stateInput = $( '.geo-address-state', $group )
		$stateSelect = $( '.geo-address-geo-states', $group )
		$countryInput = $( '.geo-address-geo-countries, .geo-address-geo-country', $group )
		$form = $stateSelect.parents('form')
		$stateFormGroup = $stateSelect.parents('.form-group')

		$countryInput.change ()->
			options.geo_country_id = $countryInput.val()
			$stateSelect.data('stateSelectVal-'+options.geo_country_id,$stateSelect.val())
			$.getJSON '/geo_states.json', options, ( data )->
				if data.states.length > 0
					$stateInput.attr('disabled','disabled').removeClass('hidden').addClass('hidden').attr('data-validate','false')
					$stateSelect.removeAttr('disabled').removeClass('hidden').attr('data-validate','true')

					$( "option:not([value=''])", $stateSelect ).remove()
					for state in data.states
						$stateSelect.append( '<option value="'+state.id+'">'+state.name+'</option>' )
					$stateSelect.val( $stateSelect.data('stateSelectVal-'+options.geo_country_id) )

					$stateFormGroup.removeClass('geo-address-geo-state-input').addClass('geo-address-geo-state-select')
				else
					$stateSelect.attr('disabled','disabled').removeClass('hidden').addClass('hidden').attr('data-validate','false')
					$stateInput.removeAttr('disabled').removeClass('hidden').attr('data-validate','true')

					$stateFormGroup.removeClass('geo-address-geo-state-select').addClass('geo-address-geo-state-input')


				$form.data('bs.validator').update() if $form.data('bs.validator')

		$countryInput.change()
