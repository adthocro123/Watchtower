Rails.application.routes.draw do
  devise_for :users

  root "dashboard#index"

  resources :events do
    member do
      post :select
      post :sync
    end
  end

  resources :scouting_entries do
    collection do
      post :sync
    end
  end

  resources :teams, only: [ :index, :show ]

  resources :pick_lists

  resources :data_conflicts, only: [ :index ] do
    member do
      post :resolve
    end
  end

  resource :match_simulator, only: [ :new, :create ], controller: "match_simulator"

  scope :exports, controller: :exports do
    get :csv, as: :exports_csv
    get :pdf, as: :exports_pdf
  end

  namespace :api do
    namespace :v1 do
      resources :scouting_entries, only: [ :create ] do
        collection do
          post :bulk_sync
        end
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
