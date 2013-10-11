$ ->
  $(document).on 'click', 'a.attachment-remove', (event) ->
    event.preventDefault()
    attachment_div = $(event.target).closest('.attachment')
    attachment_div.find('input.asset-box-remove').first().val(1)
    attachment_div.hide()

    # Show the first 'limit' attachments, hide the rest
    asset_box_input = attachment_div.closest('div.asset-box-input')
    limit = asset_box_input.data('limit')

    asset_box_input.find("input.asset-box-remove[value!='1']:gt(#{limit})").each -> $(this).closest('.attachment').hide()
    asset_box_input.find("input.asset-box-remove[value!='1']:lt(#{limit})").each -> $(this).closest('.attachment').show()

  # This is the 'admin' insert assets screen
  $(document).on 'click', 'a.asset-box-dialog', (event) ->
    obj = $(event.target)

    event.preventDefault()
    dialog_frame = $(
      "<div title='Insert Asset'>" +
        "<iframe id='wym_insert_asset_iframe' src='#{obj.data('dialog-url')}' width='100%' height='100%' marginWidth='0' marginHeight='0' frameBorder='0' scrolling='auto' title='Insert Asset'></iframe>" +
      "</div>"
    )

    dialog_frame.dialog({
      modal: true,
      height: $(window).height() * 0.85,
      width: "85%",
      close: (event, ui) -> $(this).remove()
      buttons: { Close: -> $(this).dialog("close") }
    })

    asset_box = obj.closest('.asset-box-input')

    single_mode = (asset_box.data('limit') == 1)
    attachable_id = asset_box.data('attachable-id')
    attachable_type = asset_box.data('attachable-type')
    attachable_box = asset_box.data('box')
    authenticity_token = asset_box.closest('form').find("input[name='authenticity_token']").first().val()

    $('#wym_insert_asset_iframe', dialog_frame).on 'load', ->
      $(this).contents().find('a.asset-insertable').on 'click', (event) ->
        event.preventDefault()

        # This is a bit hacky and abuses the s3uploads#update controller
        # Initialize a new Attachment and get the HTML for it.
        $.ajax({
          url: "/s3_uploads/#{$(this).data('asset-id')}",
          complete: (jqXHR, textStatus) ->
            asset_box.find('.attachments').prepend($(jqXHR.responseText))

            limit = asset_box.data('limit') - 1
            asset_box.find("input.asset-box-remove[value!='1']:gt(" + limit + ")").each -> $(this).closest('.attachment').hide()
            asset_box.find("input.asset-box-remove[value!='1']:lt(" + limit + ")").each -> $(this).closest('.attachment').show()

          global: false,
          type: 'PUT',
          dataType: 'script',
          data: {
            'authenticity_token' : authenticity_token,
            'box'       : attachable_box,
            'attachable_type' : attachable_type,
            'attachable_id' : attachable_id,
            'asset_id' : $(this).data('asset-id'),
            'skip_update' : true
          }
        })

        if single_mode then dialog_frame.dialog("close")
