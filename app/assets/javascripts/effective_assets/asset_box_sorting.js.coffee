applySortable = ->
  $(".asset-box-input .attachments").sortable
    items: '> .attachment'
    containment: 'parent'
    cursor: 'move'
    forcePlaceholderSize: true
    forceHelperSize: true

$ -> applySortable()
$(document).on 'page:change', -> applySortable()
