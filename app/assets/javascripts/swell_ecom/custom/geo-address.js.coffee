
$ ->

	$('.geo-address-country-state-group').each ->
		$group = $(this)
		options = $group.data()
		$stateInput = $( '.geo-address-state', $group )
		$stateSelect = $( '.geo-address-geo-states', $group )
		$countryInput = $( '.geo-address-geo-countries, .geo-address-geo-country', $group )

		$countryInput.change ()->
			options.geo_country_id = $countryInput.val()
			$stateSelect.data('stateSelectVal-'+options.geo_country_id,$stateSelect.val())
			$.getJSON '/geo_states.json', options, ( data )->
				if data.states.length > 0
					$stateInput.attr('disabled','disabled').removeClass('hidden').addClass('hidden')
					$stateSelect.removeAttr('disabled').removeClass('hidden')
					$( "option:not([value=''])", $stateSelect ).remove()
					for state in data.states
						$stateSelect.append( '<option value="'+state.id+'">'+state.name+'</option>' )
					$stateSelect.val( $stateSelect.data('stateSelectVal-'+options.geo_country_id) )
				else
					$stateSelect.attr('disabled','disabled').removeClass('hidden').addClass('hidden')
					$stateInput.removeAttr('disabled').removeClass('hidden')

		$countryInput.change()
