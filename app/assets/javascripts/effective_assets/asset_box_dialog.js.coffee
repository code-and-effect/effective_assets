$(document).on 'click', '.asset-box-dialog', (event) ->
  event.preventDefault()

  obj = $(event.currentTarget)
  asset_box = obj.closest('.asset-box-input')
  modal = obj.siblings('.asset-box-modal')

  return false unless modal

  iframe = modal.find('iframe')
  iframe.attr('height', $(window).height() * 0.75)

  unless asset_box.data('dialog-initialized')
    iframe.contents().on 'click', '.attachment-insert', (event) ->
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

      if asset_box.data('limit') == 1 then modal.modal('hide')

  asset_box.data('dialog-initialized', true)
  modal.modal()
