CKEDITOR.dialog.add 'effective_asset', (editor) ->
  title: 'Insert File'
  minWidth: 700,
  minHeight: 500,
  contents: [
    {
      id: 'upload',
      label: 'Insert / Upload',
      title: 'Insert / Upload',
      elements: [
        {
          id: 'iframe-insert',
          type: 'html',
          html: "<div><p id='iframe-insert-loading' style='text-align: center;'><br><br><br><br><br><br><br><br>&nbsp;&nbsp;&nbsp;Loading...</p><iframe class='effective_assets_iframe' style='width: 100%; height: 100%; min-height: 500px;' src='/effective/assets?only=nonimages'></iframe></div>"
          onLoad: (evt) ->
            dialog = evt.sender # This is the CKEditor.dialog
            iframe = $('#' + dialog.getContentElement('upload', 'iframe-insert').domId).children('iframe').first()
            iframe.on 'load', ->
              $('#iframe-insert-loading').remove()

              $(this).contents().on 'click', 'a.attachment-insert', (event) ->
                event.preventDefault()
                linkTitle = $($(event.currentTarget).data('asset')).text()

                currentAssetId = dialog.getValueOf('asset', 'asset_id')
                newAssetId = $(event.currentTarget).data('asset-id')
                # if changing or initializing the attachment
                if currentAssetId != newAssetId
                  dialog.setValueOf('asset', 'asset_id', newAssetId)
                  # if initializing the attachment
                  if currentAssetId == ''
                    # try to set the link title based on a given link title
                    givenLinkTitle = dialog.getContentElement('asset', 'link_title').getValue()
                    linkTitle = givenLinkTitle if givenLinkTitle.length > 0

                dialog.setValueOf('asset', 'link_title', linkTitle)
                dialog.commitContent()
                dialog.click('ok')
        }
      ] # /upload elements
    }, # /upload tab
    {
      id: 'asset',
      label: 'File Info',
      title: 'File Info',
      elements: [
        {
          type: 'html',
          html: "<p>* NOTE: This screen is for non-image files only. Please select 'Image' from the toolbar to work with images.",
          setup: (widget) ->
            if widget.data['asset_id']
              this.getDialog().selectPage('asset')
            else
              this.getDialog().selectPage('upload')
        },
        {
          id: 'asset_id',
          type: 'text',
          label: 'File',
          setup: (widget) ->
            this.setValue(widget.data.asset_id)
            $('#' + this.getDialog().getContentElement('asset', 'asset_id').getElement().getId()).hide()
          commit: (widget) -> widget.setData('asset_id', this.getValue()) if widget
          validate: CKEDITOR.dialog.validate.notEmpty('please select a file')
        },
        {
          id: 'link_title',
          type: 'text',
          label: 'Title',
          setup: (widget) -> this.setValue(widget.data.link_title || widget.editor.getSelection().getSelectedText())
          commit: (widget) -> widget.setData('link_title', this.getValue()) if widget
        },
        {
          id: 'html_class',
          type: 'text',
          label: 'HTML Classes',
          setup: (widget) -> this.setValue(widget.data.html_class)
          commit: (widget) -> widget.setData('html_class', this.getValue()) if widget
        },
        {
          id: 'private_url',
          type: 'checkbox',
          label: 'Link to a private URL that will expire 60 minutes after any page visit',
          setup: (widget) -> this.setValue(widget.data.private_url)
          commit: (widget) -> widget.setData('private_url', this.getValue()) if widget
        }
      ] # /asset elements
    } # /asset tab
  ] # /contents


