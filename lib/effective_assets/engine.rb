module EffectiveAssets
  class Engine < ::Rails::Engine
    engine_name 'effective_assets'

    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/inputs"]
    config.autoload_paths += Dir["#{config.root}/app/models/validators"]
    config.autoload_paths += Dir["#{config.root}/app/models/uploaders"]

    # Include Helpers to base application
    initializer 'effective_assets.action_controller' do |app|
      ActiveSupport.on_load :action_controller do
        helper EffectiveAssetsHelper
      end
    end

    # Include acts_as_addressable concern and allow any ActiveRecord object to call it
    initializer 'effective_assets.active_record' do |app|
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.extend(ActsAsAssetBox::ActiveRecord)
      end
    end

    # Set up our default configuration options.
    initializer "effective_assets.defaults", :before => :load_config_initializers do |app|
      EffectiveAssets.setup do |config|
        config.assets_table_name = :assets
        config.attachments_table_name = :attachments
        config.uploader = AssetUploader

        config.aws_final_path = 'assets/'
        config.aws_upload_path = 'uploads/'
        config.aws_acl = 'public-read'
      end
    end

    # ActiveAdmin (optional)
    # This prepends the load path so someone can override the assets.rb if they want.
    initializer 'effective_assets.active_admin' do
      if defined?(ActiveAdmin)
        ActiveAdmin.application.load_paths.unshift Dir["#{config.root}/active_admin"]
      end
    end

  end
end
