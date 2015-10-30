class User < ActiveRecord::Base
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

  has_many :operations, :dependent => :delete_all
  has_many :recharges, :dependent => :delete_all
  has_many :user_files, :dependent => :delete_all
  has_many :topology_rules_set_templates, :dependent => :delete_all

  def self.from_omniauth(auth)
    is_new = where(provider: auth.provider, uid: auth.uid).count == 0
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.skip_confirmation!
      # user.name = auth.info.name   # assuming the user model has a name
      # user.image = auth.info.image # assuming the user model has an image
      Recharge.create :user => user, :sum => 10000, :date => Time.zone.now if is_new
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

end
