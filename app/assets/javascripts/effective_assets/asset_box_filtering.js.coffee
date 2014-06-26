filter = (search, asset_box_input) ->
  term = (search || '').toLowerCase()

  asset_box_input.find('.attachments').first().find('.attachment').each (index) ->
    attachment = $(this)

    return if "#{attachment.find("input.asset-box-remove").first().val()}" == '1'

    if term == '' || attachment.find('.attachment-title').text().toLowerCase().indexOf(term) > -1
      attachment.show()
    else
      attachment.hide()

$(document).on 'keyup', '.filter-attachments', (event) ->
  obj = $(event.currentTarget)
  filter(obj.val(), obj.closest('.asset-box-input'))
