module Inputs
  class AssetBox
    delegate :content_tag, :render, :to => :@template

    def initialize(object, object_name, template, method, opts)
      @object = object
      @object_name = object_name
      @template = template
      @options = initialize_options(method, opts)
    end

    def to_html
      output = ''
      output += header_html

      if @options[:uploader] == :top
        output += uploader_html
        output += attachments_html
        output += dialog_html if @options[:dialog]
      else
        output += attachments_html
        output += dialog_html if @options[:dialog]
        output += uploader_html if @options[:uploader]
      end

      output += footer_html

      output.html_safe
    end

    private

    def header_html
      "<div class='asset-box-input #{@options[:box]}'
        data-box='#{@options[:box]}'
        data-uploader='s3_#{@options[:uid]}'
        data-limit='#{@options[:limit]}'
        data-attachable-id='#{@options[:attachable_id]}'
        data-attachable-type='#{@options[:attachable_type]}'
        data-attachable-object-name='#{@object_name}'
        data-attachment-style='#{@options[:attachment_style]}'
        data-attachment-add-to='#{@options[:attachment_add_to]}'
        data-attachment-actions='#{@options[:attachment_actions].to_json()}'
        data-aws-acl='#{@options[:aws_acl]}'
      >".html_safe
    end

    def attachments_html
      if @options[:attachment_style] == :table
        content_tag(:table, :class => 'table') do
          content_tag(:thead) do
            content_tag(:tr) do
              [
                content_tag(:th, ''),
                content_tag(:th, ''),
                content_tag(:th, (@options[:table_filter_bar] ? filter_bar_html : ''), :colspan => 2)
              ].join().html_safe
            end
          end + content_tag(:tbody, build_values_html, :class => 'attachments')
        end
      elsif @options[:attachment_style] == :list
        content_tag(:ul, build_values_html, :class => 'attachments')
      else
        content_tag(:div, build_values_html, :class => 'row attachments thumbnails')
      end
    end

    def dialog_html
      render(
        :partial => 'asset_box_input/dialog',
        :locals => {
          :dialog_url => @options[:dialog_url]
        }
      ).html_safe
    end

    def uploader_html
      render(
        :partial => 'asset_box_input/uploader',
        :locals => {
          :uid => @options[:uid],
          :limit => @options[:limit],
          :disabled => @options[:disabled],
          :file_types => @options[:file_types],
          :progress_bar_partial => @options[:progress_bar_partial],
          :drop_files => @options[:uploader_drop_files],
          :drop_files_help_text => @options[:drop_files_help_text],
          :aws_acl => @options[:aws_acl],
          :btn_label => @options[:btn_label]
        }
      ).html_safe
    end

    def filter_bar_html
      "<input type='text' class='form-control filter-attachments' placeholder='Search Title'>".html_safe
    end

    def build_values_html
      count = 0

      attachments.map do |attachment|
        count += 1 unless attachment.marked_for_destruction?

        attachment_partial =
        case @options[:attachment_style]
        when :table
          'attachment_as_table'
        when :list
          'attachment_as_list'
        when :thumbnail
          'attachment_as_thumbnail'
        when nil
          'attachment_as_thumbnail'
        else
          raise "unknown AssetBox attachment_style: #{@options[:attachment_style]}. Valid options are :thumbnail, :list and :table"
        end

        render(
          :partial => "asset_box_input/#{attachment_partial}",
          :locals => {
            :attachment => attachment,
            :attachment_actions => @options[:attachment_actions].map(&:to_s),
            :hidden => (count > @options[:limit]),
            :disabled => @options[:disabled],
            :attachable_object_name => @object_name,
          }
        )
      end.join.html_safe
    end

    def footer_html
      "</div>".html_safe
    end

    def attachments
      @object.attachments.select { |attachment| attachment.box == @options[:box] }
    end

    def initialize_options(method, opts)
      {
        :uploader => true, # :top, :bottom, true or false
        :uploader_drop_files => false,
        :drop_files_help_text => 'Drop files here',
        :progress_bar_partial => 'asset_box_input/progress_bar_template',
        :attachment_style => :thumbnail,  # :thumbnail, :table, or :list
        :attachment_add_to => :bottom, # :bottom or :top (of attachments div)
        :attachment_actions => [:remove], # or :insert, :delete, :remove
        :table_filter_bar => false,
        :dialog => false,
        :dialog_url => @template.effective_assets.effective_assets_path,
        :disabled => false,
        :file_types => [:any],
        :aws_acl => EffectiveAssets.aws_acl,
        :btn_label => "Upload files..."
      }.merge(opts).tap do |options|
        options[:method] = method.to_s
        options[:box] = method.to_s.pluralize
        options[:attachable_id] ||= (@object.try(:id) rescue nil)
        options[:attachable_type] ||= @object.class.name.titleize.gsub(" ", "_").gsub('/', '_').downcase

        options[:uid] = "#{options[:attachable_type]}-#{options[:attachable_id]}-#{options[:method]}-#{Time.zone.now.to_f}".parameterize
        options[:limit] = (options[:method] == options[:box] ? (options[:limit] || 10000) : 1)
      end
    end
  end
end

