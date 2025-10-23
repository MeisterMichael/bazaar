#= require ./plugins/jquery.payment
#= require ./plugins/jquery.card
#= require ./plugins/validator.js
#= require ./custom/stripe_integration.js
#= require ./plugins/jquery.caret.js
#= require ./plugins/jquery.mobilephonenumber.js
#= require ./custom/geo-address

$ ->

	$.fn.validator.Constructor.INPUT_SELECTOR = '.collapse.collapse-ignore.in '+$.fn.validator.Constructor.INPUT_SELECTOR+', '+$.fn.validator.Constructor.INPUT_SELECTOR+':not(.collapse.collapse-ignore :input)'

	$('.checkout_form, .payment_info_form').validator(
		custom: {
			cardnumber: ($el) ->
				if !$el.is(":focus") && ( $el.hasClass('jp-card-invalid') || !Payment.fns.validateCardNumber( $el.val() ) )
					return 'Invalid value.'
				return

			cardexpiry: ($el) ->
				expiryObjVal = Payment.fns.cardExpiryVal( $el.val() )

				if !$el.is(":focus") && ( $el.hasClass('jp-card-invalid') || !Payment.fns.validateCardExpiry( expiryObjVal.month, expiryObjVal.year ) )
					return 'Invalid date.'
				return

			cardcvc: ($el) ->
				if !$el.is(":focus") && $el.hasClass('jp-card-invalid')
					return 'Invalid value.'
				return

			dedupe: ($el) ->
				if $el.data('dedupe-target')
					$others = $($el.data('dedupe-target'))

					if ($el.val() || '').length > 0 && $el.val() == $others.val()
						return 'Duplicate value.'
				return

		#	zipcode: ($el) ->
		#	 	matchValue = $el.data('phone')
		#	  	# foo
		#	 	if $el.val() != matchValue
		#	    	return 'Hey, that\'s not valid! It\'s gotta be ' + matchValue
		#	  	return
		}
	)

	$('.same_as_shipping').change ->
		$input = $(this)
		$form = $input.parents('form')

		$form.find('.billing-address-section').find('input,select,textarea').each ->
			$(this).data( 'default-required', $(this).attr('required') ) if $(this).data('default-required') == undefined

		if $input.is(':checked')
			$form.find('.billing-address-section').addClass('hide').find('input,select,textarea').attr('data-validate','false').removeAttr( 'required' )
		else
			$form.find('.billing-address-section').removeClass('hide').find('input,select,textarea').attr('data-validate','true')
			$form.find('.billing-address-section').find('input,select,textarea').each ->
				$(this).attr('required', $(this).data('default-required') ) if $(this).data('default-required')

		$form.data('bs.validator').update() if $form.data('bs.validator')

	$('.same_as_shipping').change()

	$('form.disable_submit_after_submit').submit ->
		# Disable the submit button to prevent repeated clicks:
		$form = $(this)

		if $form.data('bs.validator') && ( $form.data('bs.validator').hasErrors() || $form.data('bs.validator').isIncomplete() )
			return false
		else
			$('input[type=submit], .submit', $form).addClass('disabled').attr('disabled', 'disabled');
			$form.addClass('submitted')

	$('.card-form-group .card-preview').each ->
		$form = $(this).parents('form')
		$form.card({
			container: '.card-preview',
			formSelectors: {
				numberInput: '.card-number',
				expiryInput: '.expiry',
				cvcInput: '.cvc'
			},
			placeholders: {
				name: '',
			}
		})

	$('.telephone_formatted').each ()->
		$(this).mobilePhoneNumber({ defaultPrefix: '+1' });
