class CommonInfo < ActiveRecord::Base

  validates_uniqueness_of :info_type, :scope => :locale
  validates_uniqueness_of :locale, :scope => :info_type

  validates :info_type, :presence => true
  validates :locale, :presence => true
  validates :text, :presence => true

  WELCOME = 0
  ABOUT = 10
  TERMS_OF_USE = 20
  PRIVACY_POLICY = 30

  rails_admin do
    object_label_method :info_title

    list do
      field :info_type, :enum do
        enum_method :info_types_enum
      end
      field :locale, :enum do
        enum_method :locales_enum
      end
    end

    show do
      field :info_type do
        formatted_value do
          CommonInfo.info_type_name value
        end
      end
      field :locale do
        formatted_value do
          PersonsHelper::LOCALES[value.to_sym]
        end
      end
      field :text do
        pretty_value do
          wiki = WikiCloth::Parser.new({
                                           :data => value,
                                           :noedit => true
                                       })
          wiki.to_html
        end
      end
    end

    edit do
      field :info_type, :enum do
        enum_method do
          :info_types_enum
        end
      end
      field :locale, :enum do
        enum_method do
          :locales_enum
        end
      end
      field :text, :ck_editor do
        partial 'wiki'
      end
    end

  end

  def self.info_type_name(type)
    case type.to_i
      when CommonInfo::WELCOME
        I18n.t 'common_info.welcome'
      when CommonInfo::ABOUT
        I18n.t 'common_info.about'
      when CommonInfo::TERMS_OF_USE
        I18n.t 'common_info.terms_of_use'
      when CommonInfo::PRIVACY_POLICY
        I18n.t 'common_info.privacy_policy'
    end
  end

  def info_title
    case info_type
      when CommonInfo::WELCOME
        I18n.t 'help.welcome'
      when CommonInfo::ABOUT
        I18n.t 'help.about'
      when CommonInfo::TERMS_OF_USE
        I18n.t 'help.terms_of_use'
      when CommonInfo::PRIVACY_POLICY
        I18n.t 'help.privacy_policy'
    end
  end

  protected

  def self.info_types_enum
    [
        WELCOME,
        ABOUT,
        TERMS_OF_USE,
        PRIVACY_POLICY
    ].map do |type|
      [CommonInfo.info_type_name(type), type]
    end
  end

  def self.locales_enum
    PersonsHelper::LOCALES.map { |locale| [locale[1], locale[0]] }
  end

end
