require 'carrierwave-aws'
require 'delayed_job_active_record'
require 'jquery-fileupload-rails'
require 'haml-rails'
require 'effective_assets/engine'
require 'effective_assets/version'

module EffectiveAssets
  AWS_PUBLIC = 'public-read'
  AWS_PRIVATE = 'authenticated-read'
  IFRAME_UPLOADS = 'effective_iframe_uploads'

  # The following are all valid config keys
  mattr_accessor :assets_table_name
  mattr_accessor :attachments_table_name

  mattr_accessor :uploader

  mattr_accessor :aws_bucket
  mattr_accessor :aws_access_key_id
  mattr_accessor :aws_secret_access_key
  mattr_accessor :aws_region

  mattr_accessor :aws_path  # This directory is where we upload files to
  mattr_accessor :aws_acl

  mattr_accessor :authorization_method

  mattr_accessor :use_active_admin

  def self.setup
    yield self

    configure_carrierwave
  end

  def self.permitted_params
    {:attachments_attributes => [:id, :asset_id, :attachable_type, :attachable_id, :position, :box, :_destroy]}
  end

  def self.authorized?(controller, action, resource)
    if authorization_method.respond_to?(:call) || authorization_method.kind_of?(Symbol)
      raise Effective::AccessDenied.new() unless (controller || self).instance_exec(controller, action, resource, &authorization_method)
    end
    true
  end

  private

  def self.configure_carrierwave
    if (@carrierwave_configured != true) && EffectiveAssets.uploader.present? && EffectiveAssets.aws_bucket.present?
      CarrierWave.configure do |config|
        config.storage        = :aws
        config.aws_bucket     = EffectiveAssets.aws_bucket
        config.aws_acl        = EffectiveAssets.aws_acl.presence || EffectiveAssets::AWS_PUBLIC
        config.cache_dir      = "#{Rails.root}/tmp/uploads" # For heroku

        config.aws_credentials = {
          :access_key_id      => EffectiveAssets.aws_access_key_id,
          :secret_access_key  => EffectiveAssets.aws_secret_access_key,
          :region             => EffectiveAssets.aws_region.presence || 'us-east-1'
        }

        config.aws_attributes = {
          :cache_control => 'max-age=315576000',
          :expires => 1.year.from_now.httpdate
        }

      end

      @carrierwave_configured = true
    end
  end

end
