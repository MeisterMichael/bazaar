
$ ->

	$('.required-if-visible input:not(:visible), .required-if-visible select:not(:visible)').each ->
		$(this).removeAttr('required')
	$('.required-if-visible input:visible, .required-if-visible input:visible').each ->
		$(this).data()
		$(this).attr('required','true')

	$('[data-toggle="tooltip"]').tooltip( html: true )

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

	$(document).on 'hide.bs.collapse', '[data-if-hidden-disable-require=true]', ->
		console.log('w00t hide')
		$('input[required], select[required]', this).data('require-if-visible','required')
		$('input, select', this).removeAttr('required')
	$(document).on 'show.bs.collapse', '[data-if-hidden-disable-require=true]', ->
		console.log('w00t show')
		$('input, select', this).each ->
			$(this).attr('required','required') if $(this).data('require-if-visible')
	$('[data-if-hidden-disable-require=true]:hidden').trigger('hide.bs.collapse')

	$('.geo_address_fields input, .geo_address_fields select').each ->
		$(this).data('old-required',$(this).attr('required'))
	$('.geo_address_fields.hide input, .geo_address_fields.hide select').each ->
		$(this).removeAttr( 'required' )
