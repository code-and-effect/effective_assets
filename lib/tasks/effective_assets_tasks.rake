# desc "Explaining what the task does"
task :reprocess_all_assets => :environment do
  Effective::DelayedJob.new().reprocess_all_assets
  Delayed::Worker.new().work_off
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
