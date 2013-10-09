$ = jQuery

$.fn.S3Uploader = (options) ->

  # support multiple elements
  if @length > 1
    @each ->
      $(this).S3Uploader options

    return this

  $uploadForm = this

  settings =
    url: ''
    before_add: null
    additional_data: null
    remove_completed_progress_bar: true
    remove_failed_progress_bar: false
    progress_bar_target: null
    progress_bar_template: null
    click_submit_target: null
    allow_multiple_files: true
    valid_s3_keys: ['utf8', 'key', 'acl', 'AWSAccessKeyId', 'policy', 'signature', 'success_action_status', 'X-Requested-With', 'content-type']
    create_asset_url: null
    update_asset_url: null

  $.extend settings, options

  current_files = []
  forms_for_submit = []
  if settings.click_submit_target
    settings.click_submit_target.click ->
      form.submit() for form in forms_for_submit
      false

  setUploadForm = ->
    $uploadForm.fileupload
      url: settings.url

      add: (e, data) ->
        file = data.files[0]

        unless settings.before_add and not settings.before_add(file)
          current_files.push data
          if (template = settings.progress_bar_template).length > 0
            data.context = $($.trim(tmpl(template.html(), file)))
            $(data.context).appendTo(settings.progress_bar_target || $uploadForm)
          else if !settings.allow_multiple_files
            data.context = settings.progress_bar_target
          if settings.click_submit_target
            if settings.allow_multiple_files
              forms_for_submit.push data
            else
              forms_for_submit = [data]
          else
            data.submit()

      start: (e) ->
        $uploadForm.trigger("s3_uploads_start", [e])

      progress: (e, data) ->
        if data.context
          progress = parseInt(data.loaded / data.total * 100, 10)
          data.context.find('.bar').css('width', progress + '%')

      done: (e, data) ->
        content = build_content_object $uploadForm, data.files[0], data.result

        if settings.update_asset_url
          update_asset_and_load_attachment(content)

        data.context.remove() if data.context && settings.remove_completed_progress_bar # remove progress bar
        $uploadForm.trigger("s3_upload_complete", [content])

        current_files.splice($.inArray(data, current_files), 1) # remove that element from the array
        $uploadForm.trigger("s3_uploads_complete", [content]) unless current_files.length

      fail: (e, data) ->
        content = build_content_object $uploadForm, data.files[0], data.result
        content.error_thrown = data.errorThrown

        data.context.remove() if data.context && settings.remove_failed_progress_bar # remove progress bar
        $uploadForm.trigger("s3_upload_failed", [content])

      formData: (form) ->
        data = form.serializeArray()

        fileType = ""
        if "type" of @files[0]
          fileType = @files[0].type
        data.push
          name: "content-type"
          value: fileType

        # Remove anything we can't submit to S3
        data = data.filter (e) -> e.name in settings.valid_s3_keys

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
    else # IE <= 9 retu      rn a null result object so we use the file object instead
      domain                 = $uploadForm.attr('action')
      content.filepath       = $uploadForm.find('input[name=key]').val().replace('/${filename}', '')
      content.url            = domain + content.filepath + '/' + encodeURIComponent(file.name)

    content.filename         = file.name
    content.filesize         = file.size if 'size' of file
    content.lastModifiedDate = file.lastModifiedDate if 'lastModifiedDate' of file
    content.filetype         = file.type if 'type' of file
    content.asset_id         = file.asset_id if 'asset_id' of file
    content.relativePath     = build_relativePath(file) if has_relativePath(file)
    content = $.extend content, settings.additional_data if settings.additional_data
    content

  has_relativePath = (file) ->
    file.relativePath || file.webkitRelativePath

  build_relativePath = (file) ->
    file.relativePath || (file.webkitRelativePath.split("/")[0..-2].join("/") + "/" if file.webkitRelativePath)

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
      async: false
      success: (data) -> asset = data

    asset

  update_asset_and_load_attachment = (file) ->
    asset_box = $uploadForm.closest('.asset-box-input')

    $.ajax
      url: settings.update_asset_url.replace(':id', file.asset_id)
      type: 'PUT'
      data:
        upload_file: unescape(file.url)
        data_size: file.filesize
        content_type: file.filetype
        attachable_type: asset_box.data('attachable-type')
        attachable_id: asset_box.data('attachable-id')
        box: asset_box.data('box')
      async: true
      success: (data) ->
        #asset_box_input.find('.attachments > div.asset-box-loading').first().remove()
        asset_box.find('.attachments').prepend($(data))

        limit = asset_box.data('limit') - 1
        asset_box.find("input.asset-box-remove[value!='1']:gt(" + limit + ")").each -> $(this).closest('div.attachment').hide()
        asset_box.find("input.asset-box-remove[value!='1']:lt(" + limit + ")").each -> $(this).closest('div.attachment').show()

  #public methods
  @initialize = ->
    # Save key for IE9 Fix
    $uploadForm.data("key", $uploadForm.find("input[name='key']").val())
    setUploadForm()
    this

  @initialize()
