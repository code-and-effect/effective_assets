Rails.application.routes.draw do
  scope :module => 'effective' do
    resources :attachments, :only => [:show]
    resources :s3_uploads, :only => [:create, :update]

    match '/effective/assets', :to => 'assets#index', :via => [:get], :as => 'effective_mercury_assets'
  end
end
