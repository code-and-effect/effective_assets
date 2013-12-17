module Effective
  class S3UploadsController < ApplicationController
    skip_authorization_check if defined?(CanCan)

    # When we create an Asset, we're effectively reserving the ID
    # But the Asset itself isn't really there or uploaded yet.
    # But we want to start uploading to the final s3 path

    def create
      EffectiveAssets.authorized?(self, :create, Effective::Asset)

      # Here we initialize an empty placeholder Asset, so we can reserve the ID
      @asset = Effective::Asset.new(:user_id => ((current_user.try(:id) || 1) rescue 1), :upload_file => 'placeholder')

      if @asset.save
        render(:text => {:id => @asset.id, :s3_key => asset_s3_key(@asset)}.to_json, :status => 200)
      else
        render(:text => '', :status => 400)
      end
    end

    def update
      asset = Effective::Asset.find(params[:id])

      EffectiveAssets.authorized?(self, :update, asset)

      unless params[:skip_update]  # This is useful for the acts_as_asset_box Attach action
        if update_placeholder_asset(asset, params) == false
          render :text => '', :status => :unprocessable_entity
          return
        end
      end

      # If the attachment information is present, then our input needs some attachment HTML
      if params.key?(:attachable_object_name)
        attachment = Effective::Attachment.new
        attachment.attachable_type = params[:attachable_type].try(:classify)
        attachment.attachable_id = params[:attachable_id].try(:to_i)
        attachment.asset_id = asset.try(:id)
        attachment.box = params[:box]
        attachment.position = 0
        attachable_object_name = params[:attachable_object_name].to_s

        partial = (params[:attachment_style].to_s == 'table' ? 'attachment_as_table' : 'attachment_as_thumbnail')

        render :partial => "asset_box_input/#{partial}", :locals => {:attachment => attachment, :attachable_object_name => attachable_object_name}, :status => 200, :content_type => 'text/html'
      else
        render :text => '', :status => 200
      end
    end

    private

    def update_placeholder_asset(asset, opts)
      asset.upload_file = opts[:upload_file]
      asset.data_size = opts[:data_size]
      asset.content_type = opts[:content_type]
      asset.aws_acl = opts[:aws_acl]
      asset.title = asset.title # This sets the Title from the filename
      asset[:data] = asset.file_name  # Using asset[:data] rather than asset.data just makes CarrierWave work

      # If our S3 Uploader has any issue uploading/saving the asset, destroy the placeholder empty one
      asset.save ? true : (asset.try(:destroy) and false)
    end

    def asset_s3_key(asset)
      "#{EffectiveAssets.aws_path.chomp('/')}/#{asset.id.to_i}/${filename}"
    end

  end
end
