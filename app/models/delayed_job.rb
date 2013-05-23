#require 'uri'
# Call with DelayedJob.new.process_asset_images(...)
# Run jobs locally with "rake jobs:work"

class DelayedJob
  def process_asset(asset)
    Rails.logger.info "ASSET UPLOAD FILE IS #{asset.upload_file}"

    if asset and !asset.processed? and asset.upload_file.present?
      begin
        puts "Processing an asset ID ##{asset.id}..."

        if asset.upload_file.include?("#{Asset.s3_base_path}")
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
        elsif asset.upload_file.include?(Asset.string_base_path)
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
    Asset.all.each do |asset|
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
  #handle_asynchronously :reprocess_all_assets
end
