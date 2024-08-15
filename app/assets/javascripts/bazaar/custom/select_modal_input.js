$(function(){

	$('.select-modal-input').each(function(i,input){
		$input = $(input)
		$input.addClass('hidden')
		$label = $('<label class="form-control select-modal-input-control"/>')
		$input.before($label)
		$input.appendTo($label)

		const uid = Math.random().toString(16).slice(2);

		label_id = $input.attr('id') + '_' + uid + '_label'
		lavel_value = $input.data('label') || $input.attr('placeholder') || ''
		$label.append('<div id="'+label_id+'" class="select-modal-input-label">'+lavel_value+'</div>')
		$input.data('label-target', $('.select-modal-input-label',$label))
	})

	$(document).on('shown.bs.modal', '.select-modal', function(e){
		var $modal = $(this)
		$('form input[type=text]',$modal).focus()
	})
	$(document).on('show.bs.modal', '.select-modal', function(e){
		var $modal = $(this)

		$('.results',$modal).empty()
		$('.filters',$modal).empty()

		$('form input[name=q]',$modal).val('')

		$modal.data('related_target',e.relatedTarget)
		$relatedTarget = $(e.relatedTarget)
		var filters = $relatedTarget.data('filters') || {}

		$.each(filters,function(key,val){
			$('.filters',$modal).append("<input type='hidden' name='"+key+"' value='"+val+"' />")
		})
	})

	function set_select_modal_input_val(related_target,option_label,option_val) {
		var $related_target = $(related_target)

		var val_target = $( $($related_target.data('val-target'))[0] || related_target )
		var label_target = $( $($related_target.data('label-target'))[0] || related_target )
		console.log('val_target',val_target,'label_target',label_target)
		if (label_target.is('input') ) {
			label_target.val(option_label)
		} else {
			label_target.html(option_label)
		}

		val_target.val(option_val)
	}

	$(document).on('click', '.select-modal .clear', function(){
		console.log('clear')
		$modal = $(this).parents('.select-modal')
		var related_target = $modal.data('related_target')

		set_select_modal_input_val(related_target,'','')

		$modal.modal('hide');
	})

	$(document).on('click', '.select-modal .choose', function(){
		$modal = $(this).parents('.select-modal')
		var option_val = $('.results input:checked', $modal).val()
		var option_label = $('.results input:checked', $modal).parent().find('.radio-label').html()
		var related_target = $modal.data('related_target')
		console.log('option_val',option_val,'option_label',option_label,related_target)
		console.log(related_target)
		var $related_target = $(related_target)

		set_select_modal_input_val(related_target,option_label,option_val)


		$modal.modal('hide');
	});


	$(document).on('submit', '.select-modal form', function(){
		$modal = $(this).parents('.select-modal')
		$('.results', $modal).empty()
		$('.results', $modal).append('<div class="text-center">Searching ...</div>')
	})


	$(document).on('ajax:success', '.select-modal form', function(e, data, status, xhr) {
		$modal = $(this).parents('.select-modal')

		$('.results', $modal).empty()
		if ( data.length == 0 ) {
			$('.results', $modal).append("<div class='text-center'>No Results</div>")
		}
		$(data).each(function(i,row){
			$('.results', $modal).append("<label><input name='offer_id' type='radio' value='"+row.id+"'/><span class='radio-label'>"+row.text+"</span></label>")
		})
		$($('.results input[type=radio]', $modal)[0]).attr('checked', 'checked');
		
	});
})
