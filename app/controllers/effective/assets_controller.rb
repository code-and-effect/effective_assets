# This is basically for the CkEditor Pictures functionality

module Effective
  class AssetsController < ApplicationController
    layout false

    def index  # This is the Modal dialog that is read by CKEDITOR
      EffectiveAssets.authorized?(self, :index, Effective::Asset.new(:user_id => current_user.try(:id)))

      @assets =  Effective::Asset.where(:user_id => current_user.try(:id))
      @aws_acl = EffectiveAssets.aws_acl.presence || 'public-read'

      if params[:only] == 'images'
        @assets = @assets.images
        @file_types = [:jpg, :gif, :png, :bmp, :ico]
        @aws_acl = 'public-read' # The CKEditor Insert Image functionality needs a public-read image here
      elsif params[:only] == 'nonimages'
        @assets = @assets.nonimages
        @file_types = [:pdf, :zip, :doc, :docx, :xls, :xlsx, :txt, :csv, :avi, :m4v, :m2v, :mov, :mp3, :mp4, :eml]
      end

      @user_uploads = UserUploads.new(@assets)

      render :file => 'effective/assets/iframe'
    end

    def destroy
      @asset = Effective::Asset.find(params[:id])
      EffectiveAssets.authorized?(self, :destroy, @asset)

      if @asset.destroy
        flash[:success] = 'Successfully deleted asset'
      else
        flash[:danger] = 'Unable to delete asset'
      end

      redirect_to(:back) rescue redirect_to(effective_assets.effective_assets_path)
    end

  end
end
