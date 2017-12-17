# frozen_string_literal: true

Rails.application.routes.draw do
  # Devise
  devise_for :admin_users, path: :admin

  scope '(:locale)', locale: /#{Settings.locales.join('|')}/ do
    root to: 'pages#index'
  end

  namespace :admin do
    root 'dashboard#index'

    resources :news, except: :show do
      member do
        get :preview
      end
    end

    resource :profile, only: %i[edit update]

    resources :partner_types, except: :show
    resources :partners, except: :show

    resources :sponsor_levels, except: :show
    resources :sponsors, except: :show

    resources :speakers, except: :show

    constraints ->(_req) { Apartment::Tenant.current == 'public' } do
      resources :sites, except: :show
    end
  end
end
