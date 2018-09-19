
$ ->

  $(document).on 'click', '[data-clone-and-append-has-many]', ->
    selector = $(this).data('clone-and-append-has-many')
    clone = $( selector ).clone()

    $('input, select', clone).each ->
      $(this).val('')
      new_name = $(this).attr( 'name' ).replace(/\[(\d+)\]/i, (str,p1,offset,s)->
        console.log( p1, parseInt( p1 ) + 1, p1 + 1 )
        return "["+( parseInt( p1 ) + 1 )+"]"
      )
      $(this).attr( 'name', new_name )
    # $('input[type=number]', clone).each ->
    #  $(this).val( $(this).attr('min') )

    $( selector ).after( clone )
    return false
