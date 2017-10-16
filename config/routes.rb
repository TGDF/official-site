Rails.application.routes.draw do
  # Devise
  devise_for :admin_users, path: :admin

  root 'pages#index'

  namespace :admin do
    root 'dashboard#index'
  end
end
