class UserFile < ActiveRecord::Base

  FILE_TYPE_REQUISITES = 0

  belongs_to :user
  after_destroy :delete_file

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

  private

  def delete_file
    File.delete file_path if File.exist? file_path
  end

end
