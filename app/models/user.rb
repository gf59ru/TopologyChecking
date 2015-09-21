class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :omniauthable,
         :omniauth_providers => [
             :google_oauth2 #,
         # :linkedin
         ]

  has_many :operations, :dependent => :delete_all
  has_many :recharges, :dependent => :delete_all

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      # user.name = auth.info.name   # assuming the user model has a name
      # user.image = auth.info.image # assuming the user model has an image
    end
  end

  def balance
    recharges = self.recharges.sum('sum')
    done_consumption = self.operations.where('state in (?) and cost > ?', [Operation::STATE_DONE, Operation::STATE_DONE_BUT_NOT_ACCESSIBLE], Operation::FREE_THRESHOLD).sum('cost')
    recharges - done_consumption - reserved
  end

  def reserved
    self.operations.where('state = ? and cost > ?', Operation::STATE_STARTED, Operation::FREE_THRESHOLD).sum('cost')
  end

end
