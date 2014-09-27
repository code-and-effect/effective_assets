require 'open-uri'

namespace :effective_assets do

  # rake reprocess_assets
  #
  # To reprocess every Asset:         rake reprocess_assets
  # Or reprocess from ID=100 and up:  rake reprocess_assets[100]
  # Or reprocess from ID=100 to 200:  rake reprocess_assets[100,200]

  # desc "Reprocesses Effective::Assets and generate versions as per the current app/uploaders/asset_uploader.rb"
  task :reprocess, [:start_at, :end_at] => :environment do |t, args|
    args.with_defaults(:start_at => 1, :end_at => Effective::Asset.unscoped.maximum(:id))
    ids = Range.new(args.start_at.to_i, args.end_at.to_i)

    puts "Enqueuing reprocess asset jobs on the Delayed::Job queue..."

    Effective::Asset.where(:processed => true).where(:id => ids).pluck(:id).each do |id|
      Effective::DelayedJob.new().reprocess_asset(id)
    end

    puts "Success. Reprocessing jobs for each Effective::Asset (IDs #{ids.to_s}) have been created on the Delayed::Job queue."
    puts "If a worker process is running, the reprocessing will have already begun."
    puts "If not, run 'rake jobs:work' to begin the worker process now."
  end

  # This is going to pull all the versions and check every url manually

  # rake check_assets
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
    errors = []

    Effective::Asset.where(:id => ids).find_each do |asset|
      (GC.start rescue nil)

      # This goes through all versions, and nil, the non-version
      ([nil] + Array(asset.data.try(:versions).try(:keys))).each do |version|
        next unless (args.version.nil? || args.version == version.to_s)

        print "checking asset ##{asset.id} :#{version || 'original'}..."

        begin
          response = Net::HTTP.get_response(URI(asset.url(version)))

          if response.code.to_i != 200
            raise "#{response.code} http code received"
          end

          success += 1
          print 'valid'; puts '';
        rescue => e
          error += 1
          message = "invalid: #{e.message}. [ERROR] #{asset.url(version) rescue ''}"

          errors << "Effective::Asset ##{asset.id} :#{version || 'original'} " + message
          print message; puts '';
        end
      end
    end

    puts "Done checking Effective::Assets (IDs #{ids.to_s}). #{success} asset versions successfully checked. #{error} found to be in error."

    if errors.present?
      puts "The following Effective::Asset version urls do not work:"
      puts errors.uniq
    end
  end

  desc "Deletes all effective_asset related Delayed::Job jobs"
  task :clear => :environment do |t, args|
    Delayed::Job.where('handler ILIKE ?', '%method_name: :process_asset_without_delay%').delete_all
    Delayed::Job.where('handler ILIKE ?', '%method_name: :reprocess_asset_without_delay%').delete_all
    puts 'Deleted all effective_asset related Delayed::Job jobs'
  end

  desc 'Create nondigest versions of some effective_assets assets'
  task :create_nondigest_assets do
    fingerprint = /\-[0-9a-f]{32}\./
    for file in Dir['public/assets/effective_assets/*.*']
      next unless file =~ fingerprint
      nondigest = file.sub fingerprint, '.' # contents-0d8ffa186a00f5063461bc0ba0d96087.css => contents.css
      FileUtils.cp file, nondigest, verbose: true
    end
  end
end

# auto run ckeditor:create_nondigest_assets after assets:precompile
Rake::Task['assets:precompile'].enhance do
  puts 'undigesting required effective_assets assets'
  Rake::Task['effective_assets:create_nondigest_assets'].invoke
end
