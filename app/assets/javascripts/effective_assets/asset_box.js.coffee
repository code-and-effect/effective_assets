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
  $attachmentDiv = $(event.target).closest('.attachment')

  $attachmentDiv.find('input.asset-box-remove').first().val(1)
  $attachmentDiv.hide()

  # Correct the attachment count
  $assetBoxInput = $attachmentDiv.closest('div.asset-box-input')
  count = parseInt($assetBoxInput.attr('data-attachment-count'), 10)
  $assetBoxInput.attr('data-attachment-count', count - 1)

