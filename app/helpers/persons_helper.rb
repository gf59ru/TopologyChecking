module PersonsHelper

  LOCALES = {
      :en => 'English',
      :ru => 'Russian (русский)'
  }

  def current_locale(en_as_default = true)
    locale = if current_user.nil?
               if params[:locale].nil?
                 cookies[:locale]
               else
                 params[:locale]
               end
             else
               current_user.locale
             end
    locale = 'en' if en_as_default && (locale.nil? || LOCALES[locale.to_sym].nil?)
    locale
  end

  def current_locale_human(en_as_default = true)
    locale = current_locale en_as_default
    locale = LOCALES[locale.to_sym]
    if locale.nil?
      I18n.t 'does_not_selected'
    else
      locale
    end
  end

  def locales_for_combobox
    LOCALES.map { |locale| [locale[1], locale[0]] }
  end

end
