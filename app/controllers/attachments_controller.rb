class AttachmentsController < ApplicationController
  authorize_resource :asset if defined? CanCan
  respond_to :json

  def show
    respond_with Asset.find(params[:id])  # This does actually search Assets
  end
end
