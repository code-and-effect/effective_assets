module Inputs
  class AssetBox
    include ActionView::Helpers::TagHelper

    def initialize(object, object_name, template, uid, method, opts)
      @object = object
      @object_name = object_name
      @template = template
      @options = initialize_options(uid, method, opts)
    end

    def to_html
      output = ''
      output += header_html
      output += attachments_html

      output += insert_dialog_html if @options[:dialog]
      output += uploader_html if @options[:uploader]

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
                content_tag(:th, 'Thumbnail'),
                content_tag(:th, 'Title'.html_safe + filter_bar_html),
                content_tag(:th, 'Size'),
                content_tag(:th)
              ].join().html_safe
            end
          end + content_tag(:tbody, build_values_html, :class => 'attachments')
        end
      else
        content_tag(:ul, build_values_html, :class => 'attachments thumbnails')
      end
    end

    def insert_dialog_html
      "<a href='#' class='asset-box-dialog' data-dialog-url='#{@options[:dialog_url]}'>Attach...</a>".html_safe
    end

    def uploader_html
      @template.render(
        :partial => 'asset_box_input/uploader',
        :locals => {
          :uid => @options[:uid],
          :limit => @options[:limit],
          :disabled => @options[:disabled],
          :file_types => @options[:file_types],
          :progress_bar_partial => @options[:progress_bar_partial],
          :aws_acl => @options[:aws_acl]
        }
      ).html_safe
    end

    def filter_bar_html
      "<input type='text' class='form-control filter-attachments' placeholder='Search'>".html_safe
    end

    def build_values_html
      count = 0

      attachments.map do |attachment|
        count += 1 unless attachment.marked_for_destruction?

        @template.render(
          :partial => "asset_box_input/#{@options[:attachment_style] == :table ? 'attachment_as_table' : 'attachment_as_thumbnail'}",
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

    def initialize_options(uid, method, opts)
      {
        :uploader => true,
        :progress_bar_partial => 'asset_box_input/progress_bar_template',
        :attachment_style => :thumbnail,  # or :table
        :attachment_actions => [:remove], # or :insert, :delete, :remove
        :dialog => false,
        :dialog_url => '/admin/effective_assets',
        :disabled => false,
        :file_types => [:any],
        :aws_acl => EffectiveAssets.aws_acl
      }.merge(opts).tap do |options|
        options[:method] = method.to_s
        options[:box] = method.to_s.pluralize
        options[:attachable_id] ||= (@object.try(:id) rescue nil)
        options[:attachable_type] ||= @object.class.name.titleize.gsub(" ", "_").gsub('/', '_').downcase

        options[:uid] = uid
        options[:limit] = (options[:method] == options[:box] ? (options[:limit] || 10000) : 1)
      end
    end
  end
end

