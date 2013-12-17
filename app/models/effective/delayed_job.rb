#require 'uri'
# Call with DelayedJob.new.process_asset_images(...)
# Run jobs locally with "rake jobs:work"

module Effective
  class DelayedJob
    def process_asset(asset)
      if asset.present? && !asset.processed? && asset.upload_file.present? && asset.upload_file != 'placeholder'
        begin
          puts "Processing asset ##{asset.id} from #{asset.upload_file}."

          if asset.upload_file.include?(Effective::Asset.string_base_path)
            puts "String-based Asset processing and uploading..."

            asset.data.cache_stored_file!
            asset.data.retrieve_from_cache!(asset.data.cache_name)
            asset.data.recreate_versions!
          elsif asset.upload_file.include?(Effective::Asset.s3_base_path)
            puts "S3 Uploaded Asset downloading and processing..."
            # Carrierwave must download the file, process it, then upload the generated versions to S3
            # We only want to process if it's an image, so we don't download zips or videos
            if asset.image?
              asset.remote_data_url = asset.url
            end
          else
            puts "Non S3 Asset downloading and processing..."

            # Carrierwave must download the file, process it, then upload it and generated verions to S3
            # We only want to process if it's an image, so we don't download zips or videos
            asset.remote_data_url = asset.upload_file
          end

          asset.processed = true
          asset.save!

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
      Effective::Asset.all.each do |asset|
        begin
          puts "Processing Asset ##{asset.id}..."
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

  end
end
