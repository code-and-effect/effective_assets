module Effective
  class S3UploadsController < ApplicationController
    skip_authorization_check if defined?(CanCan)

    # When we create an Asset, we're effectively reserving the ID
    # But the Asset itself isn't really there or uploaded yet.
    # But we want to start uploading to the final s3 path

    def create
      EffectiveAssets.authorized?(self, :create, Effective::Asset)

      if (@asset = Effective::Asset.create_from_s3_uploader(current_user.try(:id)))
        render(:text => {:id => @asset.id, :s3_key => @asset.s3_key_for_uploader}.to_json, :status => 200)
      else
        render(:text => '', :status => 400)
      end
    end

    def update
      asset = Effective::Asset.find(params[:id])

      EffectiveAssets.authorized?(self, :update, asset)

      unless params[:skip_update]  # This is useful for the acts_as_asset_box Attach action
        if asset.update_and_process(params) == false
          render :text => '', :status => :unprocessable_entity
          return
        end
      end

      # If the attachment information is present, then our input needs some attachment HTML
      if params.key?(:attachable_object_name)
        attachment = Effective::Attachment.new
        attachment.attachable_type = params[:attachable_type].try(:classify)
        attachment.attachable_id = params[:attachable_id].try(:to_i) if params[:attachable_id].present? # attachable_id can be nil if we're on a New action
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

  end
end
