require 'sidekiq/web'

# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  namespace :admin do
    resources :integrations, except: %i[show destroy]
    resource :settings, only: %i[show update]
    scope '/operator_subscriptions', controller: 'operator_subscriptions' do
      get '/:integration_id/', action: :index, as: 'operator_subscriptions'
      get '/:integration_id/:namespace/:name', action: :show, as: 'operator_subscription'
      get '/:integration_id/:namespace/:name/approve', action: :approve, as: 'approve_operator_subscription'
    end
    get '/create', to: 'create#show', as: 'create'

    resources :tasks, only: %i[new create destroy]
  end

  resources :teams do
    resources :memberships, controller: 'team_memberships', only: %i[update destroy]
  end

  resources :projects, path: 'spaces' do
    resources :resources, only: %i[new create destroy] do
      collection do
        get :bootstrap, action: :prepare_bootstrap
        post :bootstrap
      end
      member do
        get :checks, constraints: { format: 'json' }
      end
    end

    resource :integration_overrides, only: %i[show update]
  end

  resources :users, only: %i[index] do
    collection do
      get :search, constraints: { format: 'json' }
    end

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

  get '/healthz', to: 'healthcheck#show'

  root to: 'home#show'
  mount Sidekiq::Web => '/sidekiq'
end
# rubocop:enable Metrics/BlockLength
