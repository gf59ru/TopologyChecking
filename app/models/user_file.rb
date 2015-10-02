class UserFile < ActiveRecord::Base

  FILE_TYPE_REQUISITES = 0

  belongs_to :user

  def humanized_name
    name = File.basename file_path
    if description.nil?
      name
    else
      "#{name} - #{description}"
    end
  end

  def humanized_name_with_creation_date
    "#{humanized_name} (#{I18n.l created_at})"
  end

end
