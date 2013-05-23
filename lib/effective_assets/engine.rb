module EffectiveAssets
  class Engine < ::Rails::Engine
    engine_name 'effective_assets'

    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/inputs"]
    config.autoload_paths += Dir["#{config.root}/app/models/validators"]

    # Include Helpers to base application
    initializer 'effective_assets.action_controller' do |app|
      ActiveSupport.on_load :action_controller do
        helper AssetHelper
      end
    end

    # Include acts_as_addressable concern and allow any ActiveRecord object to call it
    initializer 'effective_assets.active_record' do |app|
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.extend(ActsAsAssetBox::ActiveRecord)
      end
    end

    # Set up our default configuration options.
    initializer "effective_addresses.defaults", :before => :load_config_initializers do |app|
      EffectiveAssets.setup do |config|
        config.aws_final_path = 'assets/'
        config.aws_upload_path = 'uploads/'
        config.aws_acl = 'public-read'
      end
    end

  end
end
