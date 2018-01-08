initialize = (target) ->
  $(target || document).find('div.asset-box-uploader:not(.initialized)').each (i, element) ->
    element = $(element)
    options = element.data('input-js-options') || {}

    options['progress_bar_target'] = $(element).siblings('.uploads').first()
    options['progress_bar_template'] = $(element).children("script[type='text/x-tmpl']").first()
    options['dropZone'] = $(element).parent()

    element.addClass('initialized').S3Uploader(options)

$ -> initialize()
$(document).on 'page:change', -> initialize()
$(document).on 'turbolinks:load', -> initialize()
$(document).on 'cocoon:after-insert', -> initialize()
$(document).on 'effective-form-inputs:initialize', (event) -> initialize(event.currentTarget)
