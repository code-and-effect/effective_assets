Rails.application.routes.draw do
  resources :attachments, :only => [:show]
  resources :s3_uploads, :only => [:index, :create]
end
