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

    resources :partner_types, expect: :show
    resources :partners, except: :show

    constraints ->(_req) { Apartment::Tenant.current == 'public' } do
      resources :sites, expect: :show
    end
  end
end
