#require 'uri'
# Call with DelayedJob.new.process_asset_images(...)
# Run jobs locally with "rake jobs:work"

module Effective
  class DelayedJob
    def process_asset(asset)
      DelayedJob.configure_carrierwave

      if asset and !asset.processed? and asset.upload_file.present?
        begin
          puts "Processing an asset ID ##{asset.id}..."

          if asset.upload_file.include?("#{Effective::Asset.s3_base_path}")
            if asset.image?
              puts "Asset is an image in our S3 assets directory.  Downloading and processing..."

              # Carrierwave must download the file, process it, then re-upload it to S3
              asset.remote_data_url = asset.upload_file
              asset.processed = true
              asset.save!
            else
              puts "Asset is a non-image in our S3 uploads directory.  Copying to final location..."

              # We have uploaded a video, or something non-image to our S3 bucket.
              # We do not currently process anything.

              puts "Marking local asset as processed..."
              asset.update_column(:data, asset.file_name)
              asset.processed = true
              asset.save!
            end
          elsif asset.upload_file.include?(Effective::Asset.string_base_path)
            puts "Asset is a string-based asset.  Processing..."

            asset.data.cache_stored_file!
            asset.data.retrieve_from_cache!(asset.data.cache_name)
            asset.data.recreate_versions!
            asset.processed = true
            asset.save!
          else
            puts "Asset is not an s3 uploaded asset.  Downloading and processing..."

            # Carrierwave must download the file, process it, then re-upload it to S3
            asset.remote_data_url = asset.upload_file
            asset.processed = true
            asset.save!
          end

          puts "Successfully processed the asset."
        rescue => e
          puts "An error occurred while processing an asset:"
          puts e.message
          puts e.backtrace.inspect
        end
      end
    end
    handle_asynchronously :process_asset

    def reprocess_all_assets
      DelayedJob.configure_carrierwave

      Effective::Asset.all.each do |asset|
        begin
          puts "Processing Asset ID=#{asset.id}..."
          asset.data.cache_stored_file!
          asset.data.retrieve_from_cache!(asset.data.cache_name)
          asset.data.recreate_versions!
          asset.save!
          puts "Successfully processed #{asset.inspect}"
        rescue => e
          puts  "ERROR: #{asset.id} -> #{e.to_s}"
        end
      end
    end
    handle_asynchronously :reprocess_all_assets

    def self.configure_carrierwave
      return if defined? @@configured_carrierwave

      CarrierWave.configure do |config|
        config.fog_credentials = {
          :provider               => 'AWS',
          :aws_access_key_id      => EffectiveAssets.aws_access_key_id,
          :aws_secret_access_key  => EffectiveAssets.aws_secret_access_key
        }
        config.fog_directory  = EffectiveAssets.aws_bucket
        config.fog_public     = EffectiveAssets.aws_acl.to_s.include?('public')
        config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}
        config.cache_dir      = "#{Rails.root}/tmp/uploads" # For heroku
      end

      @@configured_carrierwave = true
    end

  end
end
