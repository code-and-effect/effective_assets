require "effective_assets/engine"
require 'carrierwave'
require 'delayed_job_active_record'
require 'migrant'     # Required for rspec to run properly
require 'jquery-fileupload-rails'

module EffectiveAssets
  # The following are all valid config keys
  mattr_accessor :assets_table_name
  mattr_accessor :attachments_table_name

  mattr_accessor :uploader

  mattr_accessor :aws_bucket
  mattr_accessor :aws_access_key_id
  mattr_accessor :aws_secret_access_key

  mattr_accessor :aws_path  # This directory is where we upload files to
  mattr_accessor :aws_acl

  mattr_accessor :authorization_method

  def self.setup
    yield self

    configure_carrierwave
  end

  def self.authorized?(controller, action, resource)
    raise ActiveResource::UnauthorizedAccess.new('') unless (controller || self).instance_exec(controller, action, resource, &EffectiveAssets.authorization_method)
    true
  end

  private

  def self.configure_carrierwave
    if (@carrierwave_configured != true) && EffectiveAssets.uploader.present? && EffectiveAssets.aws_bucket.present?
      CarrierWave.configure do |config|
        config.fog_credentials = {
          :provider               => 'AWS',
          :aws_access_key_id      => EffectiveAssets.aws_access_key_id,
          :aws_secret_access_key  => EffectiveAssets.aws_secret_access_key
        }
        config.fog_directory  = EffectiveAssets.aws_bucket
        config.fog_public     = EffectiveAssets.aws_acl.to_s.include?('public')
        config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}
        config.cache_dir      = "#{Rails.root}/tmp/uploads" # For heroku
      end

      @carrierwave_configured = true
    end
  end

end
