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
      field :name
      field :locale do
        formatted_value do
          PersonsHelper::LOCALES[value]
        end
      end
    end

    show do
      field :name
      field :locale do
        formatted_value do
          PersonsHelper::LOCALES[value]
        end
      end
      field :text
    end

    edit do
      field :operation_type, :enum do
        enum do
          OperationTypeInfo::OPERATION_DEFAULT_NAMES.map do |type|
            [type[1], type[0]]
          end
        end
      end
      field :locale, :enum do
        enum do
          PersonsHelper::LOCALES.map { |locale| [locale[1], locale[0]] }
        end
      end
      field :name
      field :text, :ck_editor
    end

  end
end
