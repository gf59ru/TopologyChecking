module ApplicationHelper
  def full_title(page_title)
    base_title = t 'project_name'
    if page_title.empty?
      base_title
    else
      "#{base_title} | #{page_title}"
    end
  end

  def set_locale
    if current_user.nil? || current_user.locale.nil?
      if cookies[:locale].nil?
        I18n.locale = :en
      else
        I18n.locale = cookies[:locale]
      end
    else
      I18n.locale = current_user.locale
    end
  end
end
