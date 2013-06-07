if defined?(ActiveAdmin)
  ActiveAdmin.register Effective::Asset do
    menu :label => "Assets" #, :if => proc { can?(:manage, Asset) }, :parent => "Website Content"

    filter :title
    filter :tags
    filter :description
    filter :content_type
    filter :created_at

    scope :all, :default => true
    scope :images
    scope :videos
    scope :files

    # controller do
    #   skip_show_screen
    # end

    index do
      selectable_column

      column 'Thumbnail' do |asset|
        assets_image_tag(asset, :thumb)
      end

      column 'Title' do |asset|
        strong asset.title
        asset.tags.split(',').map { |tag| status_tag tag } if asset.tags.present?
      end

      column 'Insert' do |asset|
        ul :class => 'insert_links' do
          if asset.image?
            if asset.height.present? and asset.width.present?
              li link_to "Insert as Original (#{asset.width}x#{asset.height}px)", '#', :class => 'asset-insertable', :data => { 'asset-id' => asset.id, 'asset' => assets_image_tag(asset) }
            else
              li link_to 'Insert as Original', '#', :class => 'asset-insertable', :data => { 'asset-id' => asset.id, 'asset' => assets_image_tag(asset) }
            end

            if asset.still_processing?
              li image_tag('/assets/effective_assets/spinner.gif', :alt => 'Generating additional image sizes...')
              li 'Generating additional sizes...'
              li "Please #{link_to 'Refresh', '#', :title => 'Refresh this page', :onclick => 'window.location.reload();'} in a moment.".html_safe
            else
              asset.data.vers.each do |title, dimensions|
                li link_to "Insert as #{title.to_s.gsub('_',' ').titleize} (#{dimensions[:width]}x#{dimensions[:height]}px)", '#', :class => 'asset-insertable', :data => { 'asset-id' => asset.id, 'asset' => assets_image_tag(asset) }
              end
            end
          elsif asset.icon?
            li link_to 'Insert icon', '#', :class => 'asset-insertable', :data => { 'asset-id' => asset.id, 'asset' => assets_image_tag(asset) }

          elsif asset.video?
            li link_to 'Insert video', '#', :class => 'asset-insertable', :data => { 'asset-id' => asset.id, 'asset' => assets_video_tag(asset) }

          else
            li link_to 'Insert link to file', '#', :class => 'asset-insertable', :data => { 'asset-id' => asset.id, 'asset' => assets_file_tag(asset) }
          end

        end
      end
      default_actions
    end

    sidebar :refresh, :only => :index do
      input :type => 'submit', :value => 'Refresh Page', 'onclick' => 'window.location.reload();'
    end

    form :partial => "active_admin/form"

    show :title => :title do
      attributes_table do
        row :title
        row :description
        row :tags
        row :content_type
        row :created_at
        row :thumb do
          img :src => asset.image(:thumb)
        end
        row :files do
          ul do
            if asset.image?
              li do
                a :href => asset.image, :target => "blank" do
                  "Original"
                end
                span "#{asset.width || '?'}x#{asset.height || '?'}px #{number_to_human_size(asset.data_size, :precision => 3)}"
              end

              asset.versions_info.each do |version, attributes|
                li do
                  a :href => asset.image(version), :target => 'blank' do
                    "#{version.to_s.gsub('_',' ').titleize}"
                  end
                  span "#{attributes[:width]}x#{attributes[:height]}px #{number_to_human_size(attributes[:data_size], :precision => 3)}"
                end
              end
            else  # Asset is not an image
              li do
                a :href => asset.url do "#{asset.file_name}" end
              end
            end
          end
        end
      end
    end
  end
end
