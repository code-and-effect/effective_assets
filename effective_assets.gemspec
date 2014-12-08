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
  s.summary     = "Upload images and files directly to AWS S3 with a custom form input then seamlessly organize and attach them to any ActiveRecord object."
  s.description = "Upload images and files directly to AWS S3 with a custom form input then seamlessly organize and attach them to any ActiveRecord object."
  s.licenses    = ['MIT']

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", [">= 3.2.0"]
  s.add_dependency "carrierwave"
  s.add_dependency "coffee-rails"
  s.add_dependency "delayed_job_active_record"
  s.add_dependency "fog", ">= 1.20.0"
  s.add_dependency "jquery-rails" # For the jquery_ujs
  s.add_dependency 'unf'
  s.add_dependency "haml"
  s.add_dependency "migrant"
  s.add_dependency "mini_magick"
  s.add_dependency "jquery-fileupload-rails"
end
