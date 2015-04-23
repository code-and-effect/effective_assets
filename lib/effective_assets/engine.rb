module EffectiveAssets
  class Engine < ::Rails::Engine
    engine_name 'effective_assets'

    config.autoload_paths += Dir["#{config.root}/app/models/**/"]

    # Include Helpers to base application
    initializer 'effective_assets.action_controller' do |app|
      ActiveSupport.on_load :action_controller do
        helper EffectiveAssetsHelper
        helper EffectiveAssetsS3Helper
      end
    end

    # Include acts_as_addressable concern and allow any ActiveRecord object to call it
    initializer 'effective_assets.active_record' do |app|
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.extend(ActsAsAssetBox::ActiveRecord)
      end
    end

    initializer 'effective_assets.action_view' do |app|
      ActiveSupport.on_load :action_view do
        ActionView::Helpers::FormBuilder.send(:include, Inputs::AssetBoxFormInput)
      end
    end

    # Set up our default configuration options.
    initializer "effective_assets.defaults", :before => :load_config_initializers do |app|
      eval File.read("#{config.root}/lib/generators/templates/effective_assets.rb")
    end

    initializer "effective_assets.append_precompiled_assets" do |app|
      Rails.application.config.assets.precompile += ['effective_assets.js', 'effective_assets_iframe.js', 'effective_assets_iframe.css', 'spinner.gif']
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
