Rails.application.routes.draw do

  get 'errors/error404'

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
  get 'home/about'
  get 'home/terms_of_use'
  get 'home/privacy_policy'
  get 'home/contacts'
  get 'home/service_info'
  get 'home/operation_types_help'
  get 'home/request_new_operation_type'
  post 'home/request_new_operation_type'
  get 'home/feedback'
  post 'home/feedback'

  devise_for :users, :controllers => {
                       :omniauth_callbacks => 'users/omniauth_callbacks',
                       :sessions => 'users/sessions',
                       :registrations => 'users/registrations',
                       :confirmations => 'users/confirmations',
                       :passwords => 'users/passwords'
                   }
  devise_scope :user do
    # get 'sign_out', :to => 'devise/sessions#destroy', :as => :destroy_user_session_path
    # get 'revoke_google_oauth', :to => 'users/omniauth_callbacks#revoke_google_oauth2', :as => 'revoke_google_oauth'
  end

  root to: 'home#index'

  get 'persons/profile', as: 'user_root'
  post 'persons/update'
  get 'persons/download_user_file', :to => 'persons#download_user_file', :as => 'download_user_file'
  delete 'persons/destroy_user_file', :to => 'persons#destroy_user_file', :as => 'delete_user_file'

  # Rails.application.routes.draw do
  #   get 'errors/error404'
  #   match '/404' => 'errors#error404', :via => [:get, :post, :patch, :delete]
  # end

  get '/404' => 'errors#error404', :via => [:get, :post, :patch, :delete]
  get '/500' => 'errors#error500', :via => [:get, :post, :patch, :delete]
  post 'errors/report', :to => 'errors#report'
  post 'errors/send_report', :to => 'errors#send_report'

end
