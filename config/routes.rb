Rails.application.routes.draw do
  mount EffectiveAssets::Engine => '/', :as => 'effective_assets'
end

EffectiveAssets::Engine.routes.draw do
  scope :module => 'effective' do
    resources :s3_uploads, :only => [:create, :update]

    match '/effective/assets', :to => 'assets#index', :via => [:get], :as => 'effective_assets'
    match '/effective/assets/:id', :to => 'assets#destroy', :via => [:delete], :as => 'effective_asset'
  end
end
