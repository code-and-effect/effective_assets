require "formtastic"

# With formtastic, just use
#
# = f.input :pictures, :as => :asset_box
# = f.input :fav_icon, :as => :asset_box, :limit => 4, :file_types => [:jpg, :gif, :png]
# = f.input :logo, :as => :asset_box, :uploader => false, :dialog => true
# = f.input :logo, :as => :asset_box, :uploader => true, :uploader_visible => true

class AssetBoxInput
  include ::Formtastic::Inputs::Base

  def to_html
    @@uid = (@@uid ||= 0) + 1 # We just need a unique number to pass along, incase we have multiple SWF Uploaders per form

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
    end
  end

  def header_html
    "<div class='asset_box_input #{method.to_s.pluralize}' data-box='#{method.to_s.pluralize}' data-swf='s3_swf_#{@@uid}' data-limit='#{limit}' data-attachable-id='#{attachable_id}' data-attachable-type='#{attachable_type}'>".html_safe
  end

  def insert_uploader_html
    "<a href='#' class='asset-box-upload'>Upload...</a>".html_safe
  end

  def uploader_html
    template.render(:partial => 'asset_box_input/uploader', :locals => {:attachable_id => attachable_id, :attachable_type => attachable_type, :box => method.to_s.pluralize, :uid => @@uid, :file_types => options[:file_types], :limit => limit, :uploader_visible => options[:uploader_visible]}).html_safe
  end

  def insert_dialog_html
    "<a href='#' class='asset-box-dialog'>Attach...</a>".html_safe
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
    {:uploader => false, :dialog => false, :uploader_visible => false}.merge(super)
  end

end
