module AssetBox
  include ActionView::Context
  include ActionView::Helpers::TagHelper

  def to_html # formtastic calls to_html
    @@uid = (@@uid ||= 0) + 1 # We just need a unique number to pass along, incase we have multiple Uploaders per form

    input_wrapping do
      output = label_html
      output += header_html
      output += attachments_html

      output += insert_dialog_html if options[:dialog]
      output += uploader_html if options[:uploader]

      output += footer_html
    end.html_safe
  end

  def header_html
    "<div class='asset-box-input #{method.to_s.pluralize}' 
      data-box='#{method.to_s.pluralize}' 
      data-uploader='s3_#{@@uid}' 
      data-limit='#{limit}' 
      data-attachable-id='#{attachable_id}' 
      data-attachable-type='#{attachable_type}' 
      data-attachable-object-name='#{attachable_object_name}' 
      data-attachment-style='#{options[:attachment_style]}' 
      data-attachment-actions='#{options[:attachment_actions].to_json()}' 
      data-aws-acl='#{options[:aws_acl]}'
    >".html_safe
  end

  def footer_html
    "</div>".html_safe
  end

  def uploader_html
    template.render(
      :partial => 'asset_box_input/uploader',
      :locals => {
        :uid => @@uid,
        :limit => limit,
        :disabled => options[:disabled],
        :file_types => options[:file_types],
        :progress_bar_partial => options[:progress_bar_partial],
        :aws_acl => options[:aws_acl]
      }
    ).html_safe
  end

  def insert_dialog_html
    "<a href='#' class='asset-box-dialog' data-dialog-url='#{options[:dialog_url]}'>Attach...</a>".html_safe
  end

  def attachments_html
    if options[:attachment_style] == :table
      content_tag(:table, :class => 'table') do
        content_tag(:thead) do
          content_tag(:tr) do
            [
              content_tag(:th, 'Title'),
              content_tag(:th, 'Size'),
              content_tag(:th)
            ].join().html_safe
          end
        end + content_tag(:tbody, :class => 'attachments') { build_values_html }
      end
    else
      content_tag(:ul, :class => 'attachments thumbnails') { build_values_html }
    end
  end

  def build_values_html
    count = 0
    
    attachments.map do |attachment|
      count += 1 unless attachment.marked_for_destruction?

      template.render(
        :partial => "asset_box_input/#{options[:attachment_style] == :table ? 'attachment_as_table' : 'attachment_as_thumbnail'}",
        :locals => {
          :attachment => attachment,
          :attachment_actions => options[:attachment_actions].map(&:to_s),
          :hidden => (count > limit),
          :disabled => options[:disabled],
          :attachable_object_name => attachable_object_name,
        }
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

  def attachable_object_name
    (@builder || builder).object_name
  end

  def limit
    method.to_s == method.to_s.pluralize ? (options[:limit] || 10000) : 1
  end

  def options
    {
      :uploader => true,
      :progress_bar_partial => 'asset_box_input/progress_bar_template',
      :attachment_style => :thumbnail,  # or :table
      :attachment_actions => [:delete],
      :dialog => false,
      :dialog_url => '/admin/effective_assets',
      :disabled => false,
      :file_types => [:any],
      :aws_acl => EffectiveAssets.aws_acl
    }.merge(super)
  end

end
