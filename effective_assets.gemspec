$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "effective_assets/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "effective_assets"
  s.version     = EffectiveAssets::VERSION
  s.authors     = ["Code and Effect"]
  s.email       = ["info@codeandeffect.com"]
  s.homepage    = "https://github.com/code-and-effect/effective_assets"
  s.summary     = "Effectively manage assets (images, files, videos, etc) in your application."
  s.description = "A full solution for managing assets (images, files, videos, etc). Attach one or more assets to any model with validations. Includes an upload direct to Amazon S3 implementation based on s3_swf_upload and image processing in the background with CarrierWave and DelayedJob Formtastic input for displaying, organizing, and uploading assets direct to s3. Includes (optional but recommended) integration with ActiveAdmin"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails"
  s.add_dependency "carrierwave"
  s.add_dependency "coffee-rails"
  s.add_dependency "delayed_job_active_record"
  s.add_dependency "fog", ">= 1.8.0"
  s.add_dependency "formtastic"
  s.add_dependency "haml"
  s.add_dependency "psych"
  s.add_dependency "migrant"
  s.add_dependency "mini_magick"
  s.add_dependency "s3_swf_upload"

  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "shoulda-matchers"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "psych"

  s.add_development_dependency "guard"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "guard-livereload"
end
