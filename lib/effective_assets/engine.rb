module EffectiveAssets
  class Engine < ::Rails::Engine
    engine_name 'effective_assets'

    config.autoload_paths += Dir["#{config.root}/lib/validators/", "#{config.root}/lib/inputs/"]

    config.eager_load_paths += Dir["#{config.root}/lib/validators/", "#{config.root}/lib/inputs/"]

    # Include acts_as_addressable concern and allow any ActiveRecord object to call it
    initializer 'effective_assets.active_record' do |app|
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.extend(ActsAsAssetBox::ActiveRecord)
      end
    end

    initializer 'effective_assets.action_view' do |app|
      ActiveSupport.on_load :action_view do
        ActionView::Helpers::FormBuilder.send(:include, AssetBoxFormInput)
      end
    end

    # Set up our default configuration options.
    initializer "effective_assets.defaults", :before => :load_config_initializers do |app|
      eval File.read("#{config.root}/config/effective_assets.rb")
    end

    initializer "effective_assets.append_precompiled_assets" do |app|
      Rails.application.config.assets.precompile += [
        'effective_assets_manifest.js', 'effective_assets.js', 'effective_assets_iframe.js', 'effective_assets_iframe.css',
        'effective_assets/*', 'mime-types/*'
      ]
    end

    # ActiveAdmin (optional)
    # This prepends the load path so someone can override the assets.rb if they want.
    initializer 'effective_assets.active_admin' do
      if defined?(ActiveAdmin) && EffectiveAssets.use_active_admin == true
        ActiveAdmin.application.load_paths.unshift *Dir["#{config.root}/active_admin"]
      end
    end

  end
end
