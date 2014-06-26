applySortable = ->
  $(".asset-box-input .attachments").sortable
    items: '> .attachment'
    containment: 'parent'
    cursor: 'move'
    forcePlaceholderSize: true
    forceHelperSize: true

$ -> applySortable()
$(document).on 'page:change', -> applySortable()

$(document).on 's3_file_added', (event, file) ->
  obj = $(event.target)
  obj.closest('.error').removeClass('error')
  obj.parent().siblings('.help-inline,.inline-errors').remove()

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


# This is ActiveAdmin's Attach... functionality
$(document).on 'click', 'a.asset-box-dialog', (event) ->
  event.preventDefault()

  obj = $(event.target)
  asset_box = obj.closest('.asset-box-input')

  dialog_frame = $(
    "<div title='Insert Asset'>" +
      "<iframe id='effective_assets_iframe' src='#{obj.data('dialog-url')}' width='100%' height='100%' marginWidth='0' marginHeight='0' frameBorder='0' scrolling='auto' title='Insert Asset'></iframe>" +
    "</div>"
  )

  dialog_frame.dialog({
    modal: true,
    closeOnEscape: true,
    height: $(window).height() * 0.90,
    width: "90%",
    resizable: false,
    appendTo: asset_box,
    close: (event, ui) -> $(this).remove(),
    buttons: { Close: -> $(this).dialog("close") }
  })

  $(".ui-widget-overlay").addClass('effective-assets-overlay')
  $(".ui-dialog").addClass('effective-assets-dialog').css('left', ($(window).height() - $(window).height()*0.90) + 'px')

  $('#effective_assets_iframe', dialog_frame).on 'load', ->
    $(this).contents().find('a.asset-insertable').on 'click', (event) ->
      event.preventDefault()

      $.ajax
        url: "/s3_uploads/#{$(this).data('asset-id')}"
        type: 'PUT'
        data:
          skip_update: true
          attachable_type: asset_box.data('attachable-type')
          attachable_id: asset_box.data('attachable-id')
          attachable_object_name: asset_box.data('attachable-object-name')
          attachment_style: asset_box.data('attachment-style')
          attachment_actions: asset_box.data('attachment-actions')
          aws_acl: asset_box.data('aws-acl')
          box: asset_box.data('box')
        async: true
        success: (data) ->
          asset_box.find('.attachments').prepend($(data))

          limit = asset_box.data('limit')

          asset_box.find("input.asset-box-remove").each (index) ->
            if "#{$(this).val()}" == '1'  # If we're going to delete it...
              $(this).closest('.attachment').hide()
              limit = limit + 1
              return

            if index >= limit
              $(this).closest('.attachment').hide()
            else
              $(this).closest('.attachment').show()

      if asset_box.data('limit') == 1 then dialog_frame.dialog("close")


#### FILTERING STUFF
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

$(document).on 's3_uploads_complete', (_, uploader) -> uploader.closest('.asset-box-input').find('.filter-attachments').val('')

$(document).on 's3_upload_failed', (_, uploader, content) -> 
  uploader.closest('.asset-box-input').find('.filter-attachments').val('')
  alert("An error occurred while uploading #{content.filename}.\n\nThe returned error message is: '#{content.error_thrown}'\n\nPlease try again.")
