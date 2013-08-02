require 's3_swf_upload'
require 'base64'

module Effective
  class S3UploadsController < ApplicationController
    skip_authorize_resource if defined?(CanCan)

    respond_to :js, :xml

    include S3SwfUpload::Signature

    def index
      # This is actually a 'new' action.  Not an index.  The s3 flash uploader is hardcoded to check this url as an xml request

      EffectiveAssets.authorized?(self, :create, Effective::Asset)

      bucket          = EffectiveAssets.aws_bucket
      access_key_id   = EffectiveAssets.aws_access_key_id
      acl             = EffectiveAssets.aws_acl
      secret_key      = EffectiveAssets.aws_secret_access_key
      key             = params[:key]
      content_type    = params[:content_type]
      https           = 'false'
      error_message   = ''
      expiration_date = 1.hours.from_now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z')

      policy = Base64.encode64(
        "{
          'expiration': '#{expiration_date}',
          'conditions': [
            {'bucket': '#{bucket}'},
            {'key': '#{key}'},
            {'acl': '#{acl}'},
            {'Content-Type': '#{content_type}'},
            {'Content-Disposition': 'attachment'},
            ['starts-with', '$Filename', ''],
            ['eq', '$success_action_status', '201']
          ]
        }").gsub(/\n|\r/, '')

      signature = b64_hmac_sha1(secret_key, policy)

      respond_to do |format|
        format.xml {
          render :xml => {
            :policy          => policy,
            :signature       => signature,
            :bucket          => bucket,
            :accesskeyid     => access_key_id,
            :acl             => acl,
            :expirationdate  => expiration_date,
            :https           => https,
            :errorMessage    => error_message.to_s,
          }.to_xml
        }
      end
    end

    def create
      EffectiveAssets.authorized?(self, :create, Effective::Asset)

      # If we're passed Asset information, then create an Asset
      if params[:file_path].present?
        asset = Effective::Asset.create_from_s3_uploader(params[:file_path],
          {
            :title => params[:title],
            :description => params[:description],
            :tags => params[:tags],
            :content_type => params[:content_type],
            :data_size => params[:file_size],
            :user_id => current_user.try(:id)
          }
        )
      else
        asset = (Effective::Asset.find(params[:asset_id].to_i) rescue false)
      end

      unless asset
        render :text => '', :status => :unprocessable_entity
        return
      end

      # If the attachment information is present, then our input needs some attachment HTML
      if params.key?(:attachable_type)
        attachment = Effective::Attachment.new
        attachment.attachable_type = params[:attachable_type].try(:classify)
        attachment.attachable_id = params[:attachable_id].try(:to_i) if params[:attachable_id].present? # attachable_id can be nil if we're on a New action
        attachment.asset_id = asset.try(:id)
        attachment.box = params[:box]
        attachment.position = 0

        render :partial => 'asset_box_input/attachment_fields', :locals => {:attachment => attachment}, :status => 200, :content_type => 'text/html'
      else
        render :text => '', :status => 200
      end
    end
  end
end
