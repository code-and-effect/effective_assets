module Inputs
  class AssetBox
    delegate :content_tag, :render, :current_user, :to => :@template

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
      "<div id='asset-box-input-#{@options[:uid]}'
        class='asset-box-input #{@options[:box]}'
        data-box='#{@options[:box]}'
        data-uploader='s3_#{@options[:uid]}'
        data-limit='#{@options[:limit]}'
        data-attachable-id='#{@options[:attachable_id]}'
        data-attachable-type='#{@options[:attachable_type]}'
        data-attachable-object-name='#{@object_name}'
        data-attachment-style='#{@options[:attachment_style]}'
        data-attachment-add-to='#{@options[:attachment_add_to]}'
        data-attachment-actions='#{@options[:attachment_actions].to_json()}'
        data-attachment-count='#{attachments.length}'
        data-attachment-links='#{@options[:attachment_links]}'
        data-over-limit-alerted='false'
        data-aws-acl='#{@options[:aws_acl]}'
      >".html_safe
    end

    def attachments_html
      if @options[:attachment_style] == :table
        attachments_table_html
      elsif @options[:attachment_style] == :list
        content_tag(:ul, build_values_html, :class => 'attachments')
      else
        content_tag(:div, build_values_html, :class => 'row attachments thumbnails')
      end
    end

    def attachments_table_html
      content_tag(:table, :class => 'table') do
        head = attachments_table_head_html if @options[:table_filter_bar]
        body = content_tag(:tbody, build_values_html, :class => 'attachments')
        head ? head + body : body
      end
    end

    def attachments_table_head_html
      content_tag(:thead) do
        content_tag(:tr) do
          content_tag(:th, filter_bar_html, :colspan => 4)
        end
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
      # Check that we have permission to upload.
      asset = Effective::Asset.new(user_id: ((current_user.try(:id) || 1) rescue 1), upload_file: 'placeholder')

      unless (EffectiveAssets.authorized?(@template.controller, :create, asset) rescue false)
        @options[:btn_title] = 'Unable to upload. (cannot :create Effective::Asset)'
        @options[:disabled] = true
      end

      render(
        :partial => 'asset_box_input/uploader',
        :locals => {
          :uid => @options[:uid],
          :limit => @options[:limit],
          :disabled => @options[:disabled],
          :required => (@options[:required] == true && attachments.length == 0),
          :file_types => @options[:file_types],
          :progress_bar_partial => @options[:progress_bar_partial],
          :drop_files => @options[:uploader_drop_files],
          :drop_files_help_text => @options[:drop_files_help_text],
          :aws_acl => @options[:aws_acl],
          :btn_label => @options[:btn_label],
          :btn_title => @options[:btn_title]
        }
      ).html_safe
    end

    def filter_bar_html
      "<input type='text' class='form-control filter-attachments' placeholder='Filter by title'>".html_safe
    end

    def build_values_html
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
        :collection => attachments.reject { |attachment| attachment.marked_for_destruction? },
        :as => :attachment,
        :locals => {
          :attachment_actions => @options[:attachment_actions].map { |action| action.to_s },
          :attachment_links => @options[:attachment_links],
          :limit => @options[:limit],
          :disabled => @options[:disabled],
          :attachable_object_name => @object_name
        }
      )
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
        :attachment_links => true,
        :attachment_add_to => :bottom, # :bottom or :top (of attachments div)
        :attachment_actions => [:remove], # or :insert, :delete, :remove
        :table_filter_bar => false,
        :dialog => false,
        :dialog_url => @template.effective_assets.effective_assets_path,
        :disabled => false,
        :file_types => [:any],
        :btn_label => 'Upload...',
        :btn_title => 'Click or drag & drop to upload a file'
      }.merge(opts).tap do |options|
        options[:method] = method.to_s
        options[:box] = method.to_s.pluralize
        options[:attachable_id] ||= (@object.try(:id) rescue nil)
        options[:attachable_type] ||= @object.class.name.titleize.gsub(" ", "_").gsub('/', '_').downcase

        # The logic for the AWS ACL is such that:
        # 1.) If the :private or :aws_acl keys are set on the asset_box input, use those values
        # 2.) If the :private or :public keys are set on the acts_as_asset_box declaration, use those values
        # 3.) Fall back to default EffectiveAssets.aws_acl as per config file

        uploader_private = (opts[:private] == true || opts[:public] == false || opts[:aws_acl] == EffectiveAssets::AWS_PRIVATE)
        uploader_public = (opts[:private] == false || opts[:public] == true || opts[:aws_acl] == EffectiveAssets::AWS_PUBLIC)
        object_private = ((@object.asset_boxes[method] == :private || @object.asset_boxes[method].first[:private] == true || @object.asset_boxes[method].first[:public] == false) rescue false)
        object_public = ((@object.asset_boxes[method] == :public || @object.asset_boxes[method].first[:public] == true || @object.asset_boxes[method].first[:private] == false) rescue false)

        if uploader_private
          options[:aws_acl] = EffectiveAssets::AWS_PRIVATE
        elsif uploader_public
          options[:aws_acl] = EffectiveAssets::AWS_PUBLIC
        elsif object_private
          options[:aws_acl] = EffectiveAssets::AWS_PRIVATE
        elsif object_public
          options[:aws_acl] = EffectiveAssets::AWS_PUBLIC
        else
          options[:aws_acl] = EffectiveAssets.aws_acl
        end

        options[:uid] = "#{options[:attachable_type]}-#{options[:attachable_id]}-#{options[:method]}-#{Time.zone.now.to_f}".parameterize
        options[:limit] = (options[:method] == options[:box] ? (options[:limit] || 10000) : 1)
      end
    end
  end
end

