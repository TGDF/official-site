# frozen_string_literal: true

Rails.application.routes.draw do
  # Devise
  devise_for :admin_users, path: :admin

  scope '(:lang)', lang: /#{I18n.available_locales.join('|')}/ do
    # TODO: Use get instead resources
    root to: 'pages#index'
    resources :news, only: %i[index show]
    resources :speakers, only: %i[index show]
    resource :agenda, only: %i[show]
    resources :sponsors, only: %i[index]
    resources :indie_spaces, only: %i[index]
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
    resources :agenda_times, except: :show
    resources :agenda_days, except: :show

    resources :games, expect: :show

    constraints ->(_req) { Apartment::Tenant.current != 'public' } do
      resource :options, only: %w[edit update]
    end

    constraints ->(_req) { Apartment::Tenant.current == 'public' } do
      resources :sites, except: :show
    end
  end
end
