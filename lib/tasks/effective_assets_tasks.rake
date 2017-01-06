require 'open-uri'

namespace :effective_assets do

  # rake effective_assets:reprocess
  #
  # To reprocess every Asset:         rake reprocess_assets
  # Or reprocess from ID=100 and up:  rake reprocess_assets[100]
  # Or reprocess from ID=100 to 200:  rake reprocess_assets[100,200]

  desc "Reprocesses Effective::Assets and re-generates versions as per the current app/uploaders/asset_uploader.rb"
  task :reprocess, [:start_at, :end_at] => :environment do |t, args|
    args.with_defaults(:start_at => 1, :end_at => Effective::Asset.unscoped.maximum(:id))
    ids = Range.new(args.start_at.to_i, args.end_at.to_i)

    puts 'Reprocessing assets...'

    Effective::Asset.where(processed: true).where(id: ids).find_each do |asset|
      begin
        asset.reprocess!
        puts "Successfully reprocessed ##{asset.id}"
      rescue => e
        puts "Error reprocessing ##{asset.id}: #{e.message}"
      end
    end

    puts 'Done'
  end

  # This is going to pull all the versions and check every url manually

  # rake rake effective_assets:check
  #
  # Checks the actual HTTP response code of the URL for each asset version
  #
  # Call with rake check_assets
  # Or check_assets[100] for 100 and up
  # Or check_assets[100,200] for 100 to 200
  # Or check_assets [1,200,:thumb]
  #

  desc 'Checks the URLs for a 200 HTTP status code '
  task :check, [:start_at, :end_at, :version] => :environment do |t, args|
    args.with_defaults(:start_at => 1, :end_at => Effective::Asset.unscoped.maximum(:id), :version => nil)
    args.version.gsub!(':', '') if args.version
    ids = Range.new(args.start_at.to_i, args.end_at.to_i)

    success = 0
    error = 0
    error_ids = []
    error_urls = []

    Effective::Asset.where(:id => ids).find_each do |asset|
      (GC.start rescue nil)

      # This goes through all versions, and nil, the original file
      ([nil] + Array(asset.data.try(:versions).try(:keys))).each do |version|
        next unless (args.version.nil? || args.version == version.to_s)

        print "checking asset ##{asset.id} :#{version || 'original'}..."

        begin
          response = Net::HTTP.get_response(URI(asset.url(version)))

          if response.code.to_i != 200
            raise "#{response.code} http code received"
          end

          success += 1
          print 'valid'
        rescue => e
          error += 1
          print "invalid: #{e.message}. [ERROR] #{asset.url(version) rescue ''}"

          error_ids << asset.id
          error_urls << (asset.url(version) rescue '')
        end

        puts ''
      end
    end

    puts "Done checking Effective::Assets (IDs #{ids.to_s}). #{success} asset versions successfully checked. #{error} found to be in error."

    if error_urls.present?
      puts "The following Effective::Asset version URLs are invalid:"
      error_urls.each { |str| puts str }
      puts ''
      puts "============="
      puts "The easiest way to fix this is to open a console and run the following:"
      puts "error_ids = #{error_ids.uniq.compact.inspect}"
      puts "Effective::Asset.where(:id => error_ids).each { |asset| asset.reprocess! }"
    end
  end

end
