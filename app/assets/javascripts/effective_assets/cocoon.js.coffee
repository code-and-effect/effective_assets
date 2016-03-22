# When we add a cocoon element, it copies a static template into the DOM
# We have to update this template to have a unique ID
$(document).on 'cocoon:before-insert', (event, item) ->
  return true if item.find('.asset-box-uploader').length == 0

  html = item.html()

  item.find('.asset-box-uploader').each (index, element) =>
    from = $(element).attr('id').replace('s3_', '')
    to = from.replace(/\d.?\d/g, '') + (new Date().getTime()) + '-' + index
    html = html.replace(new RegExp(from, 'g'), to)

  item.html(html)

