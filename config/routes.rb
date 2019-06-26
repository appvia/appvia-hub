require 'sidekiq/web'

# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  namespace :admin do
    resources :integrations, except: %i[show destroy]
    resource :settings, only: %i[show update]
  end

  resources :projects, path: 'spaces' do
    resources :resources, only: %i[new create destroy] do
      collection do
        get :bootstrap, action: :prepare_bootstrap
        post :bootstrap
      end
    end

    resource :integration_overrides, only: %i[show update]
  end

  resources :users, only: %i[index] do
    resource :role, only: %i[update], controller: 'users', action: :update_role
  end

  namespace :me do
    resource :access, only: %i[show], controller: 'access'

    delete '/identities/:integration_id',
      to: 'identities#destroy',
      as: 'identity'

    scope '/identity_flows/:integration_id' do
      # GitHub
      scope '/git_hub' do
        get :start,
          to: 'identity_flows#git_hub_start',
          as: 'identity_flow_git_hub_start'

        get :callback,
          to: 'identity_flows#git_hub_callback',
          as: 'identity_flow_git_hub_callback'
      end
    end
  end

  root to: 'home#show'
  mount Sidekiq::Web => '/sidekiq'
end
# rubocop:enable Metrics/BlockLength
