# bundle exec rake replace_effective_assets
desc 'Replaces effective_assets with ActiveStorage'
task :replace_effective_assets => :environment do
  Effective::AssetReplacer.new.replace!
end
