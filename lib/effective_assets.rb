require "effective_assets/engine"
require 'carrierwave'
require 'delayed_job_active_record'
require 'migrant'     # Required for rspec to run properly

module EffectiveAssets
  # The following are all valid config keys
  mattr_accessor :assets_table_name
  mattr_accessor :attachments_table_name

  mattr_accessor :uploader

  mattr_accessor :aws_bucket
  mattr_accessor :aws_access_key_id
  mattr_accessor :aws_secret_access_key

  mattr_accessor :aws_upload_path  # This directory is where the flash s3 uploader first places files
  mattr_accessor :aws_final_path # We then authenticate and use Fog to copy the object from upload_path to final_path
  mattr_accessor :aws_acl

  mattr_accessor :authorization_method

  def self.setup
    yield self
  end

  def self.authorized?(controller, action, resource)
    raise ActiveResource::UnauthorizedAccess.new('') unless (controller || self).instance_exec(controller, action, resource, &EffectiveAssets.authorization_method)
    true
  end
end
