module AssetBox

  def to_html # formtastic calls to_html
    @@uid = (@@uid ||= 0) + 1 # We just need a unique number to pass along, incase we have multiple Uploaders per form

    input_wrapping do
      output = label_html
      output += header_html
      output += "<div class='attachments'>".html_safe
      output += build_values_html
      output += "</div>".html_safe

      if options[:uploader]
        output += insert_uploader_html
        output += uploader_html
      end

      if options[:dialog]
        output += insert_dialog_html
      end

      output += "</div>".html_safe
    end.html_safe
  end

  def header_html
    "<div class='asset-box-input #{method.to_s.pluralize}' data-box='#{method.to_s.pluralize}' data-uploader='s3_#{@@uid}' data-limit='#{limit}' data-attachable-id='#{attachable_id}' data-attachable-type='#{attachable_type}'>".html_safe
  end

  def insert_uploader_html
    "<a href='#' class='asset-box-upload'>#{options[:upload_label]}</a>".html_safe
  end

  def uploader_html
    template.render(:partial => 'asset_box_input/uploader', :locals => {:attachable_id => attachable_id, :attachable_type => attachable_type, :box => method.to_s.pluralize, :uid => @@uid, :file_types => options[:file_types], :limit => limit, :uploader_visible => options[:uploader_visible], :progress_bar_partial => options[:uploader_progress_bar_partial]}).html_safe
  end

  def insert_dialog_html
    "<a href='#' class='asset-box-dialog' data-dialog-url='#{options[:dialog_url]}'>Attach...</a>".html_safe
  end

  def build_values_html
    count = 0
    attachments_limit = limit

    attachments.map do |attachment|
      count += 1 unless attachment.marked_for_destruction?

      template.render(
        :partial => 'asset_box_input/attachment_fields',
        :locals => {:attachment => attachment, :attachable_type => attachable_type, :hidden => (count > attachments_limit) }
      )
    end.join.html_safe
  end

  def attachments
    method_name = method.to_s.pluralize
    object.attachments.select { |attachment| attachment.box == method_name }
  end

  def attachable_type
    options[:attachable_type] || object.class.name.titleize.gsub(" ", "_").gsub('/', '_').downcase
  end

  def attachable_id
    options[:attachable_id] || (object.try(:id) rescue nil)
  end

  def limit
    method.to_s == method.to_s.pluralize ? (options[:limit] || 10000) : 1
  end

  def options
    {
      :uploader => false,
      :uploader_progress_bar_partial => 'asset_box_input/progress_bar_template',
      :dialog => false,
      :dialog_url => '/admin/effective_assets',
      :uploader_visible => false,
      :upload_label => 'Upload...',
      :start_label => 'Start Uploading',
      :stop_label => 'Stop Uploading',
      :clear_label => 'Clear Queue'
    }.merge(super)
  end

end
