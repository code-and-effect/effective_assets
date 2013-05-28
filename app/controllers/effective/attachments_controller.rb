module Effective
  class AttachmentsController < ApplicationController
    authorize_resource :class => 'Effective::Asset' if defined? CanCan
    respond_to :json

    def show
      respond_with Asset.find(params[:id])  # This does actually search Assets
    end
  end
end
