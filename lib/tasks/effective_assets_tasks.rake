# rake reprocess_assets
#
# To reprocess every Asset:         rake reprocess_assets
# Or reprocess from ID=100 and up:  rake reprocess_assets[100]
# Or reprocess from ID=100 to 200:  rake reprocess_assets[100, 200]

# desc "Reprocesses Effective::Assets and generate versions as per the current app/uploaders/asset_uploader.rb"
task :reprocess_assets, [:start_at, :end_at] => :environment do |t, args|
  args.with_defaults(:start_at => 1, :end_at => Effective::Asset.unscoped.maximum(:id))
  ids = Range.new(args.start_at.to_i, args.end_at.to_i)

  puts "Enqueuing reprocess asset jobs on the Delayed::Job queue..."

  Effective::Asset.where(:processed => true).where(:id => ids).pluck(:id).each do |id|
    Effective::DelayedJob.new().reprocess_asset(id)
  end

  puts ''
  puts "Success. Reprocessing jobs for each Effective::Asset (IDs #{ids.to_s}) have been created on the Delayed::Job queue."
  puts "If a worker process is running, the reprocessing will have already begun. Otherwise, press Y to run immediately."

  puts ''
  puts "Start reprocessing right now in this process (Y/N)?"

  if STDIN.gets.chomp.upcase == 'Y'
    puts 'Starting immediately...'
    Delayed::Worker.new().work_off
  else
    puts "Exitting."
    puts "Run 'bundle exec rake jobs:work' to begin the worker process or open rails console and run Delayed::Job.delete_all"
  end

end

namespace :effective_assets do
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
