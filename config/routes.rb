Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Email subscriptions
      resources :email_subscriptions, only: [:index, :create, :destroy]
      
      # User endpoints
      get 'me', to: 'me#show'
      
      # Authentication endpoints
      post 'register', to: 'authentication#register'
      post 'login', to: 'authentication#login'
      post 'refresh', to: 'authentication#refresh'
      delete 'logout', to: 'authentication#logout'
      delete 'logout_all', to: 'authentication#logout_all'
      
      # Profile endpoints
      resource :user_profile, only: [:show, :create, :update]
      resource :nutrition_profile, only: [:show, :create, :update]
      
      # Weight tracking endpoints
      resources :weights, only: [:index, :create, :show, :destroy] do
        collection do
          get :latest
          get :trend
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

