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
