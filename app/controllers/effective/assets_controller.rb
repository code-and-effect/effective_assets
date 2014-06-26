# This is basically for the EffectiveMercury Attach Asset thingy

module Effective
  class AssetsController < ApplicationController
    layout false

    def index  # This is the Modal dialog that is read by CKEDITOR
      EffectiveAssets.authorized?(self, :index, Effective::Asset.new(:user_id => current_user.try(:id)))

      @assets = Effective::Asset.where(:user_id => current_user.try(:id)).where("#{EffectiveAssets.assets_table_name}.upload_file != ?", 'placeholder')

      if params[:only] == 'images'
        @assets = @assets.merge(Effective::Asset.images)
        @file_types = [:jpg, :gif, :png, :bmp, :ico]
      elsif params[:only] == 'nonimages'
        @assets = @assets.merge(Effective::Asset.nonimages)
        @file_types = [:pdf, :zip, :doc, :docx, :xls, :xlsx, :txt, :avi, :m4v, :m2v, :mov, :mp3, :mp4]
      end

      @user_uploads = UserUploads.new(@assets)
    end

    def destroy
      @asset = Effective::Asset.find(params[:id])
      EffectiveAssets.authorized?(self, :destroy, @asset)

      if @asset.destroy
        flash[:success] = 'Successfully deleted asset'
      else
        flash[:danger] = 'Unable to delete asset'
      end

      redirect_to(:back) rescue redirect_to(effective_assets_path)
    end
    
  end
end
