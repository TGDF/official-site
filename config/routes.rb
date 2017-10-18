Rails.application.routes.draw do
  # Devise
  devise_for :admin_users, path: :admin

  root 'pages#index'

  namespace :admin do
    root 'dashboard#index'

    constraints ->(_req) { Apartment::Tenant.current == 'public' } do
      resources :sites
    end
  end
end
