require "effective_assets/engine"
require 'migrant'     # Required for rspec to run properly

module EffectiveAssets
  # The following are all valid config keys
  mattr_accessor :aws_bucket
  mattr_accessor :aws_access_key_id
  mattr_accessor :aws_secret_access_key
  mattr_accessor :aws_upload_path

  def self.setup
    yield self
  end
end
