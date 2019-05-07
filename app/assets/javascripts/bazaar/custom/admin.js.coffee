
$ ->



	$(document).on 'click', '[data-address-toggle]', ->
		$element = $(this)
		options = $element.data('address-toggle')
		$target = $(options.target)
		open = ($element.val() == undefined) || ($element.val() == 'on')

		if open
			$target.removeClass('hide')
		else
			$target.addClass('hide')

		$( "input,select", $target ).each ->
			if open
				$(this).attr( 'required', $(this).data('old-required') )
			else
				$(this).removeAttr( 'required' )

	$('.geo_address_fields input, .geo_address_fields select').each ->
		$(this).data('old-required',$(this).attr('required'))
	$('.geo_address_fields.hide input, .geo_address_fields.hide select').each ->
		$(this).removeAttr( 'required' )
