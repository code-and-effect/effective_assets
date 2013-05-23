module EffectiveAssets
  class Engine < ::Rails::Engine
  end
end



module EffectiveAssets
  class Engine < ::Rails::Engine
    engine_name 'effective_assets'

    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]

    # Include Helpers to base application
    initializer 'effective_assets.action_controller' do |app|
      ActiveSupport.on_load :action_controller do
        #helper AddressHelper
      end
    end

    # Include acts_as_addressable concern and allow any ActiveRecord object to call it
    initializer 'effective_assets.active_record' do |app|
      ActiveSupport.on_load :active_record do
        #ActiveRecord::Base.extend(ActsAsAddressable::ActiveRecord)
      end
    end

    # Set up our default configuration options.
    initializer "effective_assets.defaults", :before => :load_config_initializers do |app|
      EffectiveAssets.setup do |config|
        #config.country_codes = %w{US CA}
      end
    end

  end
end
