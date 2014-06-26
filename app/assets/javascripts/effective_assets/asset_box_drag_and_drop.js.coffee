$(document).on 'dragenter dragover', '.asset-box-input', (event) -> $(event.currentTarget).addClass('dragin')
$(document).on 'dragleave drop', '.asset-box-input', (event) -> $(event.currentTarget).removeClass('dragin')
