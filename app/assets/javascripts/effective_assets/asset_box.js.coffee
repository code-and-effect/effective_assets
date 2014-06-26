$(document).on 's3_file_added', (event, file) ->
  obj = $(event.target)
  obj.closest('.error').removeClass('error')
  obj.parent().siblings('.help-inline,.inline-errors').remove()

$(document).on 's3_uploads_complete', (_, uploader) -> 
  uploader.closest('.asset-box-input').find('.filter-attachments').val('')

$(document).on 's3_upload_failed', (_, uploader, content) -> 
  uploader.closest('.asset-box-input').find('.filter-attachments').val('')
  alert("An error occurred while uploading #{content.filename}.\n\nThe returned error message is: '#{content.error_thrown}'\n\nPlease try again.")

$(document).on 'click', 'a.attachment-remove', (event) ->
  event.preventDefault()
  attachment_div = $(event.target).closest('.attachment')

  attachment_div.find('input.asset-box-remove').first().val(1)
  attachment_div.hide()

  # Show the first 'limit' attachments, hide the rest
  asset_box_input = attachment_div.closest('div.asset-box-input')
  limit = asset_box_input.data('limit')

  asset_box_input.find("input.asset-box-remove").each (index) ->
    if "#{$(this).val()}" == '1' # If we're going to delete it...
      $(this).closest('.attachment').hide()
      limit = limit + 1
      return

    if index >= limit
      $(this).closest('.attachment').hide()
    else
      $(this).closest('.attachment').show()



