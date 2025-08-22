Rails.application.routes.draw do
  get "billing/index"
  get "billing/create"
  get "home/index"
  get "home/pricing"
  devise_for :users, controllers: { registrations: 'registrations' }
  
  # Public pages
  root "home#index"
  get "pricing", to: "home#pricing"
  
  # Authenticated routes
  authenticate :user do
    get "dashboard", to: "dashboard#index"
    resources :site_monitors
    resources :billing, only: [:index, :create] do
      collection do
        get :portal
      end
    end
    resources :settings, only: [:index, :update]
  end
  
  # Webhooks (unauthenticated)
  post "webhooks/stripe", to: "webhooks#stripe"
  
  # Health check for monitoring
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
