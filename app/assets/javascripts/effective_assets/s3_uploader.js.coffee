$ = jQuery

$.fn.S3Uploader = (options) ->

  # support multiple elements
  if @length > 1
    @each -> $(this).S3Uploader options
    return this

  $uploadForm = this  # the .asset-box-uploader div    .asset-box-input > [.attachments, .uploads, .asset-box-uploader]

  settings =
    url: ''
    remove_completed_progress_bar: true
    remove_failed_progress_bar: true
    progress_bar_target: null
    progress_bar_template: null
    allow_multiple_files: true
    valid_s3_keys: ['key', 'acl', 'AWSAccessKeyId', 'policy', 'signature', 'success_action_status', 'X-Requested-With', 'content-type']
    create_asset_url: null
    update_asset_url: null
    file_types: 'any'

  $.extend settings, options

  current_files = []

  setUploadForm = ->
    $uploadForm.fileupload
      url: settings.url

      add: (e, data) ->
        file = data.files[0]

        # Check File Type
        if settings.file_types != 'any'
          types = new RegExp("(\.|\/)(#{settings.file_types})$")
          unless types.test(file.type) || types.test(file.name.toLowerCase())
            alert("Unable to add #{file.name}.\n\nOnly #{settings.file_types.replace(/\|/g, ', ')} files allowed.")
            return false

        if file.name.length > 180
          alert("Unable to add #{file.name}.\n\nFile name too long.  File name must be 180 or fewer characters long.")
          return false

        # We're all good. Let's go ahead and add this
        current_files.push data
        $uploadForm.trigger("s3_file_added", [e, file])

        template = settings.progress_bar_template
        data.context = $($.trim(tmpl(template.html(), file)))
        $(data.context).appendTo(settings.progress_bar_target)
        data.submit()

      start: (e) ->
        $uploadForm.trigger("s3_uploads_start", [e])
        disable_submit()

      progress: (e, data) ->
        if data.context
          progress = parseInt(data.loaded / data.total * 100, 10)
          data.context.find('.bar').css('width', progress + '%').html(format_bitrate(data.bitrate))
          data.context.find('.progress > span').remove()

      done: (e, data) ->
        content = build_content_object($uploadForm, data.files[0], data.result)

        if settings.update_asset_url
          update_asset_and_load_attachment(content)

        data.context.fadeOut('slow', -> $(this).remove()) if data.context && settings.remove_completed_progress_bar # remove progress bar
        $uploadForm.trigger("s3_upload_complete", [$uploadForm, content])

        current_files.splice($.inArray(data, current_files), 1) # remove that element from the array

        unless current_files.length
          $uploadForm.trigger("s3_uploads_complete", [$uploadForm, content])
          enable_submit()

      fail: (e, data) ->
        content = build_content_object($uploadForm, data.files[0], data.result)
        content.error_thrown = data.errorThrown

        data.context.fadeOut('slow', -> $(this).remove()) if data.context && settings.remove_failed_progress_bar # remove progress bar
        $uploadForm.trigger("s3_upload_failed", [$uploadForm, content])
        enable_submit()

      formData: (form) ->
        inputs = form.find($uploadForm).children('input')
        inputs.each -> $(this).prop('disabled', false)
        data = inputs.serializeArray()

        inputs = form.find($uploadForm).children("input:not([name='file'])")
        inputs.each -> $(this).prop('disabled', true)

        fileType = ""
        if "type" of @files[0]
          fileType = @files[0].type
        data.push
          name: "content-type"
          value: fileType

        # Remove anything we can't submit to S3
        for item in data
          data.splice(data.indexOf(data), 1) unless item.name in settings.valid_s3_keys

        # Ask our server for a unique ID for this Asset
        asset = create_asset(@files[0])
        @files[0].asset_id = asset.id
        key = asset.s3_key

        # substitute upload timestamp and unique_id into key
        key_field = $.grep data, (n) ->
          n if n.name == "key"

        if key_field.length > 0
          key_field[0].value = key

        # IE <= 9 doesn't have XHR2 hence it can't use formData
        # replace 'key' field to submit form
        unless 'FormData' of window
          $uploadForm.find("input[name='key']").val(key)
        data

  build_content_object = ($uploadForm, file, result) ->
    content = {}
    if result # Use the S3 response to set the URL to avoid character encodings bugs
      content.url            = $(result).find("Location").text()
      content.filepath       = $('<a />').attr('href', content.url)[0].pathname
    else # IE <= 9 return a null result object so we use the file object instead
      domain                 = settings.url
      content.filepath       = $uploadForm.find('input[name=key]').val().replace('/${filename}', '')
      content.url            = domain + content.filepath + '/' + encodeURIComponent(file.name)

    content.url              = s3urlDecode(content.url)
    content.filepath         = s3urlDecode(content.filepath)

    content.filename         = file.name
    content.filesize         = file.size if 'size' of file
    content.lastModifiedDate = file.lastModifiedDate if 'lastModifiedDate' of file
    content.filetype         = file.type if 'type' of file
    content.asset_id         = file.asset_id if 'asset_id' of file
    content.relativePath     = build_relativePath(file) if has_relativePath(file)
    content

  has_relativePath = (file) ->
    file.relativePath || file.webkitRelativePath

  build_relativePath = (file) ->
    file.relativePath || (file.webkitRelativePath.split("/")[0..-2].join("/") + "/" if file.webkitRelativePath)

  s3urlDecode = (url) -> url.replace(/%2F/g, "/").replace(/\+/g, '%20')

  extra_fields_for_asset = ->
    # Any field in our form that shares our name like effective_asset[#{box}][something2] should be gotten
    # And we return something2 => something2.value
    box = $uploadForm.closest('.asset-box-input').data('box')
    fields = $uploadForm.closest('form').find(":input[name*='[#{box}]']").serializeArray()

    extra = {}

    $.each fields, (i, field) ->
      pieces = field.name.split('[').map (piece) -> piece.replace(']', '')

      if (index_of_box = pieces.indexOf(box)) == -1
        name = pieces.join()
      else
        name = pieces.slice(index_of_box+1, pieces.length).join()

      extra[name] = field.value if name.length > 0

    extra

  create_asset = (file) ->
    asset = 'false'

    $.ajax
      url: settings.create_asset_url
      type: 'POST'
      dataType: 'json'
      data:
        title: file.name
        content_type: file.type
        data_size: file.size
        extra: extra_fields_for_asset()
      async: false
      success: (data) -> asset = data

    asset

  update_asset_and_load_attachment = (file) ->
    asset_box = $uploadForm.closest('.asset-box-input')

    $.ajax
      url: settings.update_asset_url.replace(':id', file.asset_id)
      type: 'PUT'
      data:
        upload_file: file.url
        data_size: file.filesize
        content_type: file.filetype
        title: file.filename
        attachable_type: asset_box.data('attachable-type')
        attachable_id: asset_box.data('attachable-id')
        attachable_object_name: asset_box.data('attachable-object-name')
        attachment_style: asset_box.data('attachment-style')
        attachment_actions: asset_box.data('attachment-actions')
        aws_acl: asset_box.data('aws-acl')
        box: asset_box.data('box')
      async: true
      success: (data) ->
        limit = asset_box.data('limit')
        direction = asset_box.data('attachment-add-to')  # bottom or top.  bottom is default append behaviour

        if limit == 10000 && direction != 'top' # Guard value for no limit.  There is no limit
          asset_box.find('.attachments').append($(data))
        else
          asset_box.find('.attachments').prepend($(data))

        asset_box.find("input.asset-box-remove").each (index) ->
          if "#{$(this).val()}" == '1'  # If we're going to delete it...
            $(this).closest('.attachment').hide()
            limit = limit + 1
            return

          if index >= limit
            $(this).closest('.attachment').hide()
          else
            $(this).closest('.attachment').show()


  disable_submit = ->
    $uploadForm.data('effective-assets-uploading', true)

    $uploadForm.closest('form').find('input[type=submit]').each ->
      submit = $(this)
      submit.data('effective-assets-original-label', submit.val()) if submit.data('effective-assets-original-label') == undefined
      submit.prop('disabled', true)
      submit.val('Uploading...')

  enable_submit = ->
    $uploadForm.data('effective-assets-uploading', false)

    anyUploading = false
    $uploadForm.closest('form').find('.asset-box-uploader').each ->
      anyUploading = true if $(this).data('effective-assets-uploading') == true

    unless anyUploading
      $uploadForm.closest('form').find('input[type=submit]').each ->
        submit = $(this)
        submit.val(submit.data('effective-assets-original-label') || 'Submit')
        submit.prop('disabled', false)
        submit.removeData('effective-assets-original-label')

  format_bitrate = (bits) ->
    if typeof bits != 'number'
      ''
    else if (bits >= 1000000000)
      (bits / 1000000000).toFixed(2) + ' Gbit/s'
    else if (bits >= 1000000)
      (bits / 1000000).toFixed(2) + ' Mbit/s'
    else if (bits >= 1000)
      (bits / 1000).toFixed(2) + ' kbit/s'
    else
      bits.toFixed(2) + ' bit/s'

  #public methods
  @initialize = ->
    # Save key for IE9 Fix
    $uploadForm.data("key", $uploadForm.find("input[name='key']").val())
    setUploadForm()
    this

  @initialize()
