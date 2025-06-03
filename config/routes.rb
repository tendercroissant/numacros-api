Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Authentication resources
      namespace :auth do
        resource :registration, only: [:create]
        resource :session, only: [:create]
        resource :token, only: [] do
          collection do
            post :refresh_token
            delete :logout_all
          end
        end
      end
      
      # Email subscriptions
      resources :email_subscriptions, only: [:index, :create, :destroy]
      
      # User-owned resources
      namespace :users do
        # User profile (singular resource)
        resource :profile, only: [:show, :update]
        
        # User settings (singular resource)
        resource :setting, only: [:show, :update]
        
        # User weights (collection resource)
        resources :weights, only: [:index, :create, :destroy] do
          collection do
            get :current
          end
        end
      end
    end
  end

  namespace :admin do
    post 'login', to: 'sessions#create'
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end

