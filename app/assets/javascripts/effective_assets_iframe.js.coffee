getCkEditorFuncNum = ->
  reParam = new RegExp( '(?:[\?&]|&)' + 'CKEditorFuncNum' + '=([^&]+)', 'i' )
  match = window.location.search.match(reParam)

  if match && match.length > 0
    match[1]

$(document).on 'click', 'a.attachment-insert', (event) ->
  ckeditor = getCkEditorFuncNum()

  if ckeditor && window.opener && window.opener.CKEDITOR
    event.preventDefault()

    obj = $(event.currentTarget)
    asset = $(obj.data('asset'))

    url = asset.attr('src') || asset.attr('href')
    alt = asset.attr('alt') || ''

    window.opener.CKEDITOR.tools.callFunction(ckeditor, url, ->
      dialog = this.getDialog()

      if dialog && dialog.getName() == 'image2'
        dialog.getContentElement('info', 'alt').setValue(alt)
    )

    window.close()

