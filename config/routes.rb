require 'sidekiq/web'

Rails.application.routes.draw do
  namespace :admin do
    resources :integrations, except: %i[show destroy]
  end

  resources :projects do
    resources :resources, only: [:destroy] do
      post :provision, on: :collection
    end
  end

  resources :users, only: %i[index] do
    resource :role, only: %i[update], controller: 'users', action: :update_role
  end

  root to: 'home#show'
  mount Sidekiq::Web => '/sidekiq'
end
