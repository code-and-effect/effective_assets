Rails.application.routes.draw do
  scope :module => 'effective' do
    resources :attachments, :only => [:show]
    resources :s3_uploads, :only => [:create, :update]
  end
end
