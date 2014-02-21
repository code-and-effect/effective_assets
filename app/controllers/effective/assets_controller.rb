# This is basically for the EffectiveMercury Attach Asset thingy

module Effective
  class AssetsController < ApplicationController
    layout false

    def index  # This is the Modal dialog
      EffectiveAssets.authorized?(self, :index, Effective::Asset.new(:user_id => current_user.try(:id)))

      @user_uploads = UserUploads.new(current_user)

      render 'assets/iframe'
    end

  end
end
