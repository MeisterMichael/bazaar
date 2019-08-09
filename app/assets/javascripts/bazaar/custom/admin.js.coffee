
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


	$('input[data-expand][type="radio"]').each ->
		name = $(this).attr('name')
		$(document).on 'change', 'input[name="' + name + '"]', ->
			$('input[name="' + name + '"]').not($(this)).trigger('deselect');

	$(document).on 'change deselect', '[data-expand]', ->
		$target = $($(this).data('expand'))
		if $(this).is(':checked')
			$target.collapse('show')
		else
			$target.collapse('hide')

	$('.geo_address_fields input, .geo_address_fields select').each ->
		$(this).data('old-required',$(this).attr('required'))
	$('.geo_address_fields.hide input, .geo_address_fields.hide select').each ->
		$(this).removeAttr( 'required' )
