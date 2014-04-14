# getArticles = ->
#   articles = []

#   $.ajax
#     url: '/effective/snippets/article_with_excerpt'
#     type: 'GET'
#     dataType: 'json'
#     async: false
#     complete: (data) -> articles = data.responseJSON

#   articles

# CKEDITOR.dialog.add 'effective_asset', (editor) ->
#   title: 'Effective Asset'
#   minWidth: 200,
#   minHeight: 100,
#   contents: [
#     {
#       id: 'effective_asset',
#       elements: [
#         {
#           id: 'asset_id',
#           type: 'select',
#           label: 'Asset',
#           items: [[1, 'something'], [2,'something else']]  # This only runs once, when the Dialog is created.
#           setup: (widget) -> this.setValue(widget.data.asset_id)
#           commit: (widget) -> widget.setData('asset_id', this.getValue())
#         }
#       ]
#     }
#   ]


CKEDITOR.dialog.add 'effective_asset', (editor) ->
  title: 'Effective Asset'
  minWidth: 650,
  minHeight: 500,
  contents: [
    {
      id: 'tab1',
      label: 'Asset',
      title: 'Asset',
      elements: [
        {
          id: 'asset_id',
          type: 'text',
          label: 'Asset ID',
          setup: (widget) -> this.setValue(widget.data.asset_id)
          commit: (widget) -> widget.setData('asset_id', this.getValue())
        },
        {
          id: 'html-class',
          type: 'text',
          label: 'HTML Class',
          setup: (widget) -> this.setValue(widget.data.html_class)
          commit: (widget) -> widget.setData('html_class', this.getValue())
        }
      ] # /tab1 elements
    }, # /tab1
    {
      id: 'tab2',
      label: 'Insert',
      title: 'Insert',
      elements: [
        {
          id: 'tab2-insert',
          type: 'html',
          html: "<div><iframe class='effective_assets_iframe' style='width: 100%; height: 100%; min-height: 500px;' src='/effective/assets'></iframe></div>"
        }
      ] # /tab2 elements
    } # /tab2
    {
      id: 'tab3',
      label: 'Upload',
      title: 'Upload',
      elements: [
        {
          id: 'tab2-upload',
          type: 'html',
          html: "<div><iframe class='effective_assets_iframe' style='width: 100%; height: 100%; min-height: 500px;' src='/effective/assets/new'></iframe></div>"
        }
      ] # /tab3 elements
    } # /tab3
  ] # /contents












