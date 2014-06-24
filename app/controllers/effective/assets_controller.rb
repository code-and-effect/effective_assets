# This is basically for the EffectiveMercury Attach Asset thingy

module Effective
  class AssetsController < ApplicationController
    layout false

    def index  # This is the Modal dialog that is read by CKEDITOR
      EffectiveAssets.authorized?(self, :index, Effective::Asset.new(:user_id => current_user.try(:id)))

      @assets = Effective::Asset.where(:user_id => current_user.try(:id))

      if params[:only] == 'images'
        @assets = @assets.merge(Effective::Asset.images)
        @file_types = [:jpg, :gif, :png, :bmp, :ico]
      elsif params[:only] == 'nonimages'
        @assets = @assets.merge(Effective::Asset.nonimages)
        @file_types = [:pdf, :zip, :doc, :docx, :xls, :xlsx, :txt, :avi, :m4v, :m2v, :mov, :mp3, :mp4]
      end

      @user_uploads = UserUploads.new(@assets)

      render 'iframe'
    end
    
  end
end
