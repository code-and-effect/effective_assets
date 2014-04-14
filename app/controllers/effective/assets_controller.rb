# This is basically for the EffectiveMercury Attach Asset thingy

module Effective
  class AssetsController < ApplicationController
    layout false

    def index  # This is the Modal dialog
      EffectiveAssets.authorized?(self, :index, Effective::Asset.new(:user_id => current_user.try(:id)))

      @user_uploads = UserUploads.new(current_user)

      render 'iframe_index'
    end

    def new  # This is a Modal dialog
      EffectiveAssets.authorized?(self, :new, Effective::Asset.new(:user_id => current_user.try(:id)))

      @user_uploads = UserUploads.new() # could pass current_user

      render 'iframe_new'
    end

  end
end
