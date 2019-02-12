require 'sidekiq/web'

Rails.application.routes.draw do
  root to: 'home#show'
  mount Sidekiq::Web => '/sidekiq'
end
