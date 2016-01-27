class OperationTypeInfo < ActiveRecord::Base
  include PersonsHelper

  validates_uniqueness_of :operation_type, :scope => :locale
  validates_uniqueness_of :locale, :scope => :operation_type

  validates :operation_type, :presence => true
  validates :locale, :presence => true
  validates :name, :presence => true
  validates :text, :presence => true

  # ќнлайн операции (выполн€ютс€ у нас на сервере)
  TOPOLOGY_VALIDATING = 1
  SERVER_OPERATIONS = [
      OperationTypeInfo::TOPOLOGY_VALIDATING
  ]

  # ќффлайн операции (скачиваемые инструменты, выполн€ющиес€ у клиента)
  GEOMETRY_TRANSFORMATION = -1
  TOOLS = [
      OperationTypeInfo::GEOMETRY_TRANSFORMATION
  ]

  OPERATION_DEFAULT_NAMES = {
      OperationTypeInfo::TOPOLOGY_VALIDATING => 'Topology validating',
      OperationTypeInfo::GEOMETRY_TRANSFORMATION => 'Geometry transformation tool'
  }

  def self.operation_type_name(operation_type)
    locale = if defined? current_locale
               current_locale
             else
               'en'
             end
    type_info = OperationTypeInfo.where('operation_type = ? and locale = ?', operation_type, locale).first
    if type_info.nil?
      nil
    else
      type_info.name
    end
  end


  rails_admin do
    object_label_method :name

    list do
      field :name do
        filterable false
      end
      field :operation_type, :enum do
        visible false
        enum_method :operation_types_enum
      end
      field :locale, :enum do
        enum_method :locales_enum
      end
    end

    show do
      field :name
      field :locale do
        formatted_value do
          PersonsHelper::LOCALES[value.to_sym]
        end
      end
      field :text
    end

    edit do
      field :operation_type, :enum do
        enum_method :operation_types_enum
      end
      field :locale, :enum do
        enum_method :locales_enum
      end
      field :name
      field :text, :ck_editor do
        partial 'wiki'
      end
    end

  end

  protected

  def self.operation_types_enum
    OperationTypeInfo::OPERATION_DEFAULT_NAMES.map { |type| [type[1], type[0]] }
  end

  def self.locales_enum
    PersonsHelper::LOCALES.map { |locale| [locale[1], locale[0]] }
  end

end
