module EffectiveAssets
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      desc 'Creates an EffectiveAssets initializer in your application.'

      source_root File.expand_path('../../templates', __FILE__)

      def self.next_migration_number(dirname)
        if not ActiveRecord::Base.timestamped_migrations
          Time.new.utc.strftime("%Y%m%d%H%M%S")
        else
          "%.3d" % (current_migration_number(dirname) + 1)
        end
      end

      def copy_initializer
        template ('../' * 3) + 'config/effective_assets.rb', 'config/initializers/effective_assets.rb'
      end

      def copy_uploader
        template 'asset_uploader.rb', 'app/uploaders/asset_uploader.rb'
      end

      def create_migration_file
        @assets_table_name = ':' + EffectiveAssets.assets_table_name.to_s
        @attachments_table_name = ':' + EffectiveAssets.attachments_table_name.to_s
        migration_template ('../' * 3) + 'db/migrate/01_create_effective_assets.rb.erb', 'db/migrate/create_effective_assets.rb'
      end

      def install_delayed_jobs
        run 'rails generate delayed_job:active_record'
      end
    end
  end
end
