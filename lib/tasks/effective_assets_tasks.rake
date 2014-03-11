# desc "Explaining what the task does"
task :reprocess_all_assets => :environment do
  Effective::DelayedJob.new().reprocess_all_assets
  Delayed::Worker.new().work_off
end
