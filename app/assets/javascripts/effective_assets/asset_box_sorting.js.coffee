applySortable = ->
  $(".asset-box-input .attachments").sortable
    items: '> .attachment'
    placeholder: 'col-sm-3'
    cursor: 'move'

$ -> applySortable()
$(document).on 'page:change', -> applySortable()
$(document).on 'turbolinks:load', -> applySortable()
