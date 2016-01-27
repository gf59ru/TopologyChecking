class User < ActiveRecord::Base

  validate :email_with_oauth

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :registerable,
         :confirmable,
         :async,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable,
         :omniauthable,
         :omniauth_providers => [
             :google_oauth2,
             :linkedin
         ]

  rails_admin do
    object_label_method :email

    list do
      field :email
      field :provider, :enum do
        label 'OAuth provider'
        enum do
          User.omniauth_providers.map { |provider| [provider.to_s.humanize, provider.to_s] }
        end
      end
      field :locale, :enum do
        enum_method :locales_enum
      end
      field :is_admin do
        label 'Administrator'
      end
    end

    show do
      field :email
      field :provider do
        label 'OAuth provider'
        formatted_value do
          (Users::OmniauthCallbacksController.provider_human_name value).capitalize unless value.nil?
        end
      end
      field :sign_in_count do
        label 'Signed in times'
      end
      field :current_sign_in_at do
        label 'Signed in at'
      end
      field :last_sign_in_at do
        label 'Last signed in at'
      end
      field :current_sign_in_ip do
        label 'Signed in from IP'
      end
      field :last_sign_in_ip do
        label 'Last signed from IP'
      end
      field :is_admin do
        label 'Administrator'
      end
      field :locale do
        formatted_value do
          PersonsHelper::LOCALES[value]
        end
      end
      field :user_files
    end

    edit do
      field :email
      field :provider do
        label 'OAuth provider'
        read_only true
        formatted_value do
          (Users::OmniauthCallbacksController.provider_human_name value).capitalize unless value.nil?
        end
      end
      field :is_admin do
        label 'Administrator'
      end
      field :locale, :enum do
        enum_method :locales_enum
      end
    end
  end

  has_many :operations, :dependent => :delete_all
  has_many :recharges, :dependent => :delete_all
  has_many :user_files, :dependent => :delete_all
  has_many :topology_rules_set_templates, :dependent => :delete_all

  def self.from_omniauth(auth)
    # is_new = where(provider: auth.provider, uid: auth.uid).count == 0
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.skip_confirmation!
      # user.name = auth.info.name   # assuming the user model has a name
      # user.image = auth.info.image # assuming the user model has an image
      # Recharge.create :user => user, :sum => 10000, :date => Time.zone.now if is_new
    end
  end

  def balance
    recharges = self.recharges.sum('sum')
    done_consumption = self.operations.where('state in (?) and cost >= ?', [Operation::STATE_DONE.to_s], Operation::FREE_THRESHOLD).sum('cost')
    recharges - done_consumption - reserved
  end

  def reserved
    self.operations.where('state in (?) and cost >= ?', [Operation::STATE_STARTED.to_s, Operation::STATE_NEED_PAYMENT.to_s], Operation::FREE_THRESHOLD).sum('cost')
  end

  def requisites_files
    user_files.where 'file_type = ?', UserFile::FILE_TYPE_REQUISITES
  end

  protected

  def email_with_oauth
    if email_changed? && !provider.nil? && persisted?
      errors.add :email, :can_not_change_when_oauth
    end
  end

  def self.locales_enum
    PersonsHelper::LOCALES.map { |locale| [locale[1], locale[0]] }
  end

end
