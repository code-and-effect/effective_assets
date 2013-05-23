var s3_queueChangeHandler = function(s3_swf, queue) {
  var obj = $("div.asset_box_input[data-swf='" + s3_swf + "']").find('div.asset_box_uploader').first();
  var list = obj.find('.file_todo_list');

  var queueBytesTotal = 0;
  var queueFiles = obj.data('queueFiles') || 0;

  // Go through the queue, find anything that doesn't exist in the list, and add it to list
  // Also add up the queueBytesTotal
  for(x = 0; x < queue.files.length; x++) {
    queueBytesTotal = queueBytesTotal + queue.files[x].size;
    var one_file = list.find("li[data-name='" + queue.files[x].name + "']");
    if(one_file.length == 0) {
      s3_addFileToTodoList(s3_swf, queue.files[x].name, queue.files[x].size, x);
    }
  }

   //Go through the list, find anything that doesn't exist in the queue, and remove it
   $('li.file_to_upload', list).each(function(i, el) {
     var name_to_find = $(el).data('name');
     var found_it = false;

     for(x = 0; x < queue.files.length; x++) {
       if(queue.files[x].name == name_to_find) {
         found_it = true;
         break;
       }
     }

     if(found_it == false) $(el).remove();
   });

   obj.find('.file_done_list').find('li').show();

  if(queue.files.length > queueFiles) obj.data('queueBytesTotal', queueBytesTotal);
  obj.data('queueFiles', queue.files.length);
};

var s3_uploadingStartHandler = function(s3_swf) {
  var obj = $("div.asset_box_input[data-swf='" + s3_swf + "']").find('div.asset_box_uploader').first();

  obj.data('queueBytesFinished', 0);
  var queueBytesTotal = obj.data('queueBytesTotal');

  obj.find('.queue_size').find('.numerator').text("0 bytes / ");
  obj.find('.queue_size').find('.denominator').text(s3_readableBytes(queueBytesTotal));
};

var s3_uploadingFinishHandler = function(s3_swf) {
  var obj = $("div.asset_box_input[data-swf='" + s3_swf + "']").find('div.asset_box_uploader').first();

  obj.find('.overall').find('.progress').css('width', '100%');
  obj.find('.overall').find('.amount').text('100%');
};

var s3_progressHandler = function(s3_swf, progress_event) {
  var obj = $("div.asset_box_input[data-swf='" + s3_swf + "']").find('div.asset_box_uploader').first();
  var current_percentage = Math.floor((parseInt(progress_event.bytesLoaded)/parseInt(progress_event.bytesTotal))*100)+'%';

  var first_file = obj.find('.file_todo_list').find('li.file_to_upload').first();
  first_file.find('.delete').hide();
  first_file.find('.progress').css('display','block').css('width', current_percentage);
  first_file.find('.progress').find('.amount').text(current_percentage);

  var queueBytesFinished = parseInt(obj.data('queueBytesFinished'));
  var queueBytesTotal = parseInt(obj.data('queueBytesTotal'));

  var overall_percentage = Math.floor(((queueBytesFinished+parseInt(progress_event.bytesLoaded))/queueBytesTotal)*100)+'%';

  // Overall
  obj.find('.overall').find('.progress').css('width', overall_percentage).show();
  obj.find('.overall').find('.amount').text(overall_percentage);
  obj.find('.queue_size').find('.numerator').text(s3_readableBytes(queueBytesFinished+parseInt(progress_event.bytesLoaded)) + " / ");
};

var s3_queueClearHandler = function(s3_swf, queue) {
  var obj = $("div.asset_box_input[data-swf='" + s3_swf + "']").find('div.asset_box_uploader').first();

  var overall = obj.find('div.overall');

  overall.find('span.progress').css('width', '0%').hide();
  overall.find('span.amount').html('0%');

  obj.find('.file_done_list').children().remove();
  obj.find('.file_todo_list').children().remove();

  obj.find('.queue_size').find('.numerator').text('');
  obj.find('.queue_size').find('.denominator').text('');
};

var s3_addFileToDoneList = function(s3_swf, file_name, file_size) {
  var obj = $("div.asset_box_input[data-swf='" + s3_swf + "']").find('div.asset_box_uploader').first();

  var queueBytesFinished = parseInt(obj.data('queueBytesFinished'));
  queueBytesFinished = queueBytesFinished + parseInt(file_size);
  obj.data('queueBytesFinished', queueBytesFinished);

  var one_file = $(
    '<li class="file_to_upload" data-name="' + file_name + '" style="display: none;">' +
      '<span class="progress">' +
        '<span class="amount">100%</span>' +
      '</span>' +
      '<span class="file_name">' + file_name + '</span>' +
      '<span class="file_size">' + s3_readableBytes(file_size) + '</span>' +
    '</li>'
    );

  obj.find('.file_done_list').first().append(one_file);
};

var s3_addFileToTodoList = function(s3_swf, file_name, file_size, index) {
  var obj = $("div.asset_box_input[data-swf='" + s3_swf + "']").find('div.asset_box_uploader').first();

  var one_file = $(
    '<li class="file_to_upload" data-name="' + file_name + '">' +
      '<span class="progress">' +
        '<span class="amount">0%</span>' +
      '</span>' +
      '<span class="file_name">' + file_name + '</span>' +
      '<span class="file_size">' + s3_readableBytes(file_size) + '</span>' +
      '<a href="#" class="delete" onclick="javascript:' + s3_swf + '_object.removeFileFromQueue(\''+file_name+'\'); return false;">Delete</span></a>' +
      '<span class="properties">' +
        '<label>Title</label>' +
        '<input type="text" class="title" value="' + file_name + '"/>' +
        '<label>Description</label>' +
        '<input type="text" class="description" />' +
        '<label>Tags</label>' +
        '<input type="text" class="tags"/>' +
      '</span>' +
    '</li>'
    );

  obj.find('.file_todo_list').first().append(one_file);
};

var s3_loadAttachmentHtml = function(s3_swf, html) {
  var asset_box_input = $("div.asset_box_input[data-swf='" + s3_swf + "']");

  asset_box_input.find('.attachments > div.asset-box-loading').first().remove()
  asset_box_input.find('.attachments').prepend($(html));

  var limit = asset_box_input.data('limit') - 1;
  asset_box_input.find("input.asset-box-remove[value!='1']:gt(" + limit + ")").each(function(i) { $(this).closest('div.asset-box-attachment').hide(); });
  asset_box_input.find("input.asset-box-remove[value!='1']:lt(" + limit + ")").each(function(i) { $(this).closest('div.asset-box-attachment').show(); });
};

var s3_showAttachmentLoading = function(s3_swf, title) {
  var asset_box_input = $("div.asset_box_input[data-swf='" + s3_swf + "']");

  var loading_html = $(
    '<div class="asset-box-attachment asset-box-loading">' +
      '<span class="thumbnail">' +
        '<i class="asset-box-spinner"></i>' +
      '</span>' +
      '<p class="title">' + title + '</p>' +
    '</div>'
    );

  asset_box_input.find('.attachments').prepend($(loading_html));
};

var s3_readableBytes = function(bytes) {
  var s = ['bytes', 'kb', 'MB', 'GB', 'TB', 'PB'];
  var e = Math.floor(Math.log(bytes)/Math.log(1024));
  return (bytes/Math.pow(1024, Math.floor(e))).toFixed(2)+" "+s[e];
};
