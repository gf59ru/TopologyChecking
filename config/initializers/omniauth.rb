# Rails.application.config.middleware.use OmniAuth::Builder do
#   provider :google_oauth2,
#            # Переменные среды, в которых хранятся id гугл-клиента и гугл-секрет
#            # https://console.developers.google.com/project/checktopology/apiui/credential
#            ENV['CHECK_TOPOLOGY_GOOGLE_CLIENT_ID'], ENV['CHECK_TOPOLOGY_GOOGLE_CLIENT_SECRET'],
#            {
#                :name => 'google',
#                :scope => 'email, profile',
#                :prompt => 'select_account',
#                :image_aspect_ratio => 'square',
#                :image_size => 50,
#                :client_options => {
#                    :ssl => {
#                        :ca_file => Rails.root.join('cert/ca-bundle.crt').to_s,
#                        :ca_path => Rails.root.join('cert').to_s
#                    }
#                }
#            }#,
#            #on_failure { |env| Devise::SessionsController.action(:failure).call(env) }
# end