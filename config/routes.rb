Rails.application.routes.draw do

  get '/auth/:action/callback' => 'sessions#create'

  get 'application/select_locale', :to => 'application#select_locale', :as => 'select_locale'

  post 'operations/next_step', :to => 'operations#next_step', :as => 'next_step'
  get 'operations/download', :to => 'operations#download', :as => 'download_operation_result'
  get 'operations/delete_rule', :to => 'operations#delete_rule', :as => 'delete_rule'
  post 'operations/payment', :to => 'operations#payment', :as => 'payment'
  get 'operations/pay_from_card', :to => 'operations#pay_from_card', :as => 'pay_from_card'
  get 'operations/pay_from_balance', :to => 'operations#pay_from_balance', :as => 'pay_from_balance'
  post 'operations/pay_callback', :to => 'operations#pay_callback', :as => 'pay_callback'
  post 'operations/pay_ok', :to => 'operations#pay_ok', :as => 'pay_ok'
  post 'operations/pay_ko', :to => 'operations#pay_ko', :as => 'pay_ko'
  get 'operations/requisites', :to => 'operations#requisites', :as => 'requisites'
  get 'operations/invoice', :to => 'operations#invoice', :as => 'invoice'
  post 'operations/invoice', :to => 'operations#invoice', :as => 'post_invoice'

  resources :operations
  resources :operation_types
  resources :operation_steps

  get 'home/index'
  get 'home/contacts'
  get 'home/service_info'
  get 'home/operation_types_help'

  devise_for :users, :controllers => {:omniauth_callbacks => 'users/omniauth_callbacks', :sessions => 'users/sessions', :registrations => 'users/registrations'}
  devise_scope :user do
    # get 'sign_out', :to => 'devise/sessions#destroy', :as => :destroy_user_session_path
    # get 'revoke_google_oauth', :to => 'users/omniauth_callbacks#revoke_google_oauth2', :as => 'revoke_google_oauth'
  end

  root to: 'home#index'

  get 'persons/profile', as: 'user_root'
  post 'persons/update'
  get 'persons/download_user_file', :to => 'persons#download_user_file', :as => 'download_user_file'
  delete 'persons/destroy_user_file', :to => 'persons#destroy_user_file', :as => 'delete_user_file'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
