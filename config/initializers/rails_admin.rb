RailsAdmin.config do |config|

  config.main_app_name = Proc.new { |controller| ['Spatial operations', "Admin - #{controller.params[:action].try(:titleize)}"] }

  ### Popular gems integration

  ## == Devise ==
  config.authenticate_with do
    if current_user.nil? || !current_user.is_admin?
      redirect_to main_app.root_url
    else
      warden.authenticate! scope: :user
    end
  end
  config.current_user_method(&:current_user)
  config.included_models = %w(User Operation Recharge CommonInfo OperationTypeInfo)

  ## == Cancan ==
  # config.authorize_with :cancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  config.actions do
    dashboard # mandatory
    index # mandatory
    new do
      except Operation
    end
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end
end
