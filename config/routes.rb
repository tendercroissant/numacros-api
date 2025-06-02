Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      namespace :auth do
        post 'signup', to: 'registrations#create'
        post 'login', to: 'sessions#create'
        post 'refresh_token', to: 'tokens#refresh'
        delete 'logout_all', to: 'tokens#logout_all'
      end
      
      resources :email_subscriptions, only: [:create, :index, :destroy]
      
      get 'profile', to: 'profile#show'
      put 'profile', to: 'profile#update'
      
      resources :weights, only: [:index, :create, :destroy] do
        collection do
          get :current
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

