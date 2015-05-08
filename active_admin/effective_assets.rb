if defined?(ActiveAdmin)
  ActiveAdmin.register Effective::Asset do
    menu :label => "Assets", :if => proc { EffectiveAssets.authorized?(controller, :manage, Effective::Asset.new()) rescue false }

    filter :title
    filter :content_type
    filter :created_at

    scope :all, :default => true
    scope :images
    scope :videos
    scope :files

    index do
      selectable_column

      column 'Thumbnail' do |asset|
        effective_asset_image_tag(asset, nil, {:height => 100, :width => 100})
      end

      column 'Title' do |asset|
        strong asset.title
      end

      column 'Insert' do |asset|
        ul :class => 'insert_links' do
          if asset.image?
            if asset.height.present? and asset.width.present?
              li link_to "Insert as Original (#{asset.width}x#{asset.height}px)", '#', :class => 'asset-insertable', :data => { 'asset-id' => asset.id, 'asset' => effective_asset_image_tag(asset) }
            else
              li link_to 'Insert as Original', '#', :class => 'asset-insertable', :data => { 'asset-id' => asset.id, 'asset' => effective_asset_image_tag(asset) }
            end

            unless asset.processed?
              li image_tag('/assets/effective_assets/spinner.gif', :alt => 'Generating additional image sizes...')
              li 'Generating additional sizes...'
              li "Please #{link_to 'Refresh', '#', :title => 'Refresh this page', :onclick => 'window.location.reload();'} in a moment.".html_safe
            else
              asset.versions_info.each do |title, dimensions|
                li link_to "Insert as #{title.to_s.gsub('_',' ').titleize} (#{dimensions[:width]}x#{dimensions[:height]}px)", '#', :class => 'asset-insertable', :data => { 'asset-id' => asset.id, 'asset' => effective_asset_image_tag(asset) }
              end
            end

            li link_to 'Reprocess all Versions', reprocess_admin_effective_asset_path(asset)

          elsif asset.icon?
            li link_to 'Insert icon', '#', :class => 'asset-insertable', :data => { 'asset-id' => asset.id, 'asset' => effective_asset_image_tag(asset) }

          elsif asset.video?
            li link_to 'Insert video', '#', :class => 'asset-insertable', :data => { 'asset-id' => asset.id, 'asset' => effective_asset_video_tag(asset) }

          else
            li link_to 'Insert link to file', '#', :class => 'asset-insertable', :data => { 'asset-id' => asset.id, 'asset' => effective_asset_link_to(asset) }
          end
        end
      end

      ActiveAdmin::VERSION.to_i >= 1 ? actions : default_actions
    end

    form :partial => "active_admin/effective_assets/form"

    show :title => :title do
      attributes_table do
        row :title
        row :content_type
        row :created_at
        row :thumb do
          effective_asset_image_tag(effective_asset, nil, {:height => 100, :width => 100})
        end
        row :files do
          ul do
            if effective_asset.image?
              li do
                a :href => effective_asset.url, :target => "blank" do
                  "Original"
                end
                span "#{effective_asset.width || '?'}x#{effective_asset.height || '?'}px #{number_to_human_size(effective_asset.data_size, :precision => 3)}"
              end

              effective_asset.versions_info.each do |version, attributes|
                li do
                  a :href => effective_asset.url(version), :target => 'blank' do
                    "#{version.to_s.gsub('_',' ').titleize}"
                  end
                  span "#{attributes[:width]}x#{attributes[:height]}px #{number_to_human_size(attributes[:data_size], :precision => 3)}"
                end
              end
            else  # Asset is not an image
              li do
                a :href => effective_asset.url do "#{effective_asset.file_name}" end
              end
            end
          end
        end
      end
    end

    member_action :reprocess, :method => :get do
      asset = Effective::Asset.find(params[:id]).reprocess!
      redirect_to admin_effective_assets_path
    end
  end
end
