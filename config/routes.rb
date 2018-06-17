# frozen_string_literal: true

Rails.application.routes.draw do
  # Devise
  devise_for :admin_users, path: :admin

  scope '(:lang)', lang: /#{I18n.available_locales.join('|')}/ do
    root to: 'pages#index'
    resources :news, only: %i[index show]
    resources :speakers, only: %i[index show]
  end

  namespace :admin do
    root 'dashboard#index'

    resources :news, except: :show do
      member do
        get :preview
      end
    end

    resource :profile, only: %i[edit update]

    resources :sliders, except: :show

    resources :partner_types, except: :show
    resources :partners, except: :show

    resources :sponsor_levels, except: :show
    resources :sponsors, except: :show

    resources :speakers, except: :show
    resources :agendas, except: :show
    resources :rooms, except: :show

    constraints ->(req) { Apartment::Tenant.current != 'public' } do
      resource :options, only: %w[edit update]
    end

    constraints ->(_req) { Apartment::Tenant.current == 'public' } do
      resources :sites, except: :show
    end
  end
end
