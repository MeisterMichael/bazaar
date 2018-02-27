#= require ./plugins/jquery.payment
#= require ./plugins/jquery.card
#= require ./plugins/validator.js
#= require ./custom/stripe_integration.js
#= require ./plugins/jquery.caret.js
#= require ./plugins/jquery.mobilePhoneNumber.js
#= require ./custom/geo-address

$ ->

	$.fn.validator.Constructor.INPUT_SELECTOR = '.collapse.collapse-ignore.in '+$.fn.validator.Constructor.INPUT_SELECTOR+', '+$.fn.validator.Constructor.INPUT_SELECTOR+':not(.collapse.collapse-ignore :input)'

	$('.checkout_form, .payment_info_form').validator(
		custom: {
			cardnumber: ($el) ->
				if ( $el.hasClass('jp-card-invalid') || !Payment.fns.validateCardNumber( $el.val() ) )
					return 'Invalid value.'
				return

			cardexpiry: ($el) ->
				expiryObjVal = Payment.fns.cardExpiryVal( $el.val() )

				if ( $el.hasClass('jp-card-invalid') || !Payment.fns.validateCardExpiry( expiryObjVal.month, expiryObjVal.year ) )
					return 'Invalid date.'
				return

			cardcvc: ($el) ->
				if $el.hasClass('jp-card-invalid')
					return 'Invalid value.'
				return
		#	zipcode: ($el) ->
		#	 	matchValue = $el.data('phone')
		#	  	# foo
		#	 	if $el.val() != matchValue
		#	    	return 'Hey, that\'s not valid! It\'s gotta be ' + matchValue
		#	  	return
		}
	)

	$('form.disable_submit_after_submit').submit ->
		# Disable the submit button to prevent repeated clicks:
		$form = $(this)

		if $form.data('bs.validator')
			# if !$form.data('bs.validator').hasErrors() && !$form.data('bs.validator').isIncomplete()
			# 	$('input[type=submit], .submit', $form).addClass('disabled').attr('disabled', 'disabled');
		else
			$('input[type=submit], .submit', $form).addClass('disabled').attr('disabled', 'disabled');
			$form[0].submit()

		return false;

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
