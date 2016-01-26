class Recharge < ActiveRecord::Base
  belongs_to :user

  rails_admin do
    object_label_method :label

    list do
      field :user
      field :date
      field :sum
    end

    show do
      field :user
      field :date
      field :sum
    end

    edit do
      field :user do
        read_only true
      end
      field :date
      field :sum
    end
  end

  def label
    if new_record?
      'New recharge'
    else
      dt = date.strftime('%d.%m.%Y')
      if user.nil?
        "No user #{sum} #{dt}"
      else
        "#{user.email} #{sum} #{dt}"
      end
    end
  end
end
