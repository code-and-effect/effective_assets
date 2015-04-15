module Effective
  class S3UploadsController < ApplicationController
    skip_authorization_check if defined?(CanCan)
    skip_before_filter :verify_authenticity_token

    # When we create an Asset, we're effectively reserving the ID
    # But the Asset itself isn't really there or uploaded yet.
    # But we want to start uploading to the final s3 path

    def create
      # Here we initialize an empty placeholder Asset, so we can reserve the ID
      @asset = Effective::Asset.new(:user_id => ((current_user.try(:id) || 1) rescue 1), :upload_file => 'placeholder')
      @asset.extra = params[:extra] if params[:extra].kind_of?(Hash)

      EffectiveAssets.authorized?(self, :create, @asset)

      begin
        @asset.save!
        render(:text => {:id => @asset.id, :s3_key => asset_s3_key(@asset)}.to_json, :status => 200)
      rescue => e
        render(:text => e.message, :status => 500)
      end
    end

    def update
      @asset = Effective::Asset.find(params[:id])

      EffectiveAssets.authorized?(self, :update, @asset)

      unless params[:skip_update]  # This is useful for the acts_as_asset_box Attach action
        if update_placeholder_asset(@asset, params) == false
          render :text => '', :status => :unprocessable_entity
          return
        end
      end

      # If the attachment information is present, then our input needs some attachment HTML
      if params.key?(:attachable_object_name)
        attachment = Effective::Attachment.new
        attachment.attachable_type = params[:attachable_type].try(:classify)
        attachment.attachable_id = params[:attachable_id].try(:to_i)
        attachment.asset_id = @asset.try(:id)
        attachment.box = params[:box]
        attachment.position = 0
        attachable_object_name = params[:attachable_object_name].to_s
        attachment_actions = params[:attachment_actions]

        attachment_partial =
        case params[:attachment_style].to_s
        when 'table'
          'attachment_as_table'
        when 'list'
          'attachment_as_list'
        else # :thumbnail, nil, or anything
          'attachment_as_thumbnail'
        end

        render :partial => "asset_box_input/#{attachment_partial}", :locals => {:attachment => attachment, :attachable_object_name => attachable_object_name, :attachment_actions => attachment_actions}, :status => 200, :content_type => 'text/html'
      else
        render :text => '', :status => 200
      end
    end

    private

    def update_placeholder_asset(asset, opts)
      asset.upload_file = opts[:upload_file]
      asset.data_size = opts[:data_size]
      asset.content_type = opts[:content_type]
      asset.title = opts[:title]
      asset.aws_acl = opts[:aws_acl]
      asset[:data] = opts[:title]

      # If our S3 Uploader has any issue uploading/saving the asset, destroy the placeholder empty one
      asset.save ? true : (asset.try(:destroy) and false)
    end

    def asset_s3_key(asset)
      "#{EffectiveAssets.aws_path.chomp('/')}/#{asset.id.to_i}/${filename}"
    end

  end
end
