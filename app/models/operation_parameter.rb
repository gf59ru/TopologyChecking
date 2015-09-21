class OperationParameter < ActiveRecord::Base

  ### Типы параметров
  # Простые типы
  TYPE_STRING = 0
  TYPE_INTEGER = 1
  TYPE_FLOAT = 2
  TYPE_BOOLEAN = 3
  # Файлы
  TYPE_FILE_TO_ARCGIS = 10 # Файл для передачи на сервер ArcGis
  TYPE_FILE_FROM_ARCGIS = 11 # Файл, получаемый с сервера ArcGis
  TYPE_FILE_LOCAL = 12 # Файл для локального хранения (без обмена с сервером ArcGis)

  ### Параметры для стандартной операции
  PARAM_UPLOADED_GDB_ZIP = 0 # Путь к zip-файлу с gdb, загруженноому пользователем на сервер
  PARAM_UPLOADED_GDB_PATH = 1 # Путь к распакованному GDB на сервере ArcGis
  PARAM_CLASSES = 2 # Наборы классов
  PARAM_ERROR_MESSAGE = 3 # Сообщение об ошибке
  PARAM_ERROR_DETAILS = 4 # Детали сообщения об ошибке
  # Распаковка GDB
  PARAM_UNZIP_JOB_ID = 100 # Задача по распаковке архива с GDB - id
  PARAM_UNZIP_JOB_URL = 101 # Задача по распаковке архива с GDB - ссылка
  PARAM_UNZIP_JOB_STATE = 102 # Задача по распаковке архива с GDB - состояние
  PARAM_UNZIP_JOB_MESSAGE = 103 # Задача по распаковке архива с GDB - сообщение
  PARAM_UNZIP_JOB_WARNING = 104 # Задача по распаковке архива с GDB - предупреждение
  PARAM_UNZIP_JOB_ERROR = 105 # Задача по распаковке архива с GDB - ошибка
  PARAM_UNZIP_JOB_EMPTY = 106 # Задача по распаковке архива с GDB - пустое сообщение
  PARAM_UNZIP_JOB_ABORT = 107 # Задача по распаковке архива с GDB - отмена
  # Свойства GDB
  # PARAM_LINES_COUNT = 200 # Количество линий
  # PARAM_POLYGONS_COUNT = 201 # Количество полигонов
  # PARAM_POINTS_COUNT = 202 # Количество точек
  # PARAM_FEATURE_CLASS_LINE = 203 # Класс пространственных объектов - линия
  # PARAM_FEATURE_CLASS_POLYGON = 204 # Класс пространственных объектов - полигон
  # PARAM_FEATURE_CLASS_POINT = 205 # Класс пространственных объектов - точка
  # Правила
  PARAM_RULE_JSON = 300 # Правило топологии
  # Проверка топологии
  PARAM_VALIDATE_JOB_ID = 400 # Задача проверки топологии - id
  PARAM_VALIDATE_JOB_URL = 401 # Задача проверки топологии - ссылка
  PARAM_VALIDATE_JOB_STATE = 402 # Задача проверки топологии - состояние
  PARAM_VALIDATE_JOB_MESSAGE = 403 # Задача проверки топологии - сообщение
  PARAM_VALIDATE_JOB_WARNING = 404 # Задача проверки топологии - предупреждение
  PARAM_VALIDATE_JOB_ERROR = 405 # Задача проверки топологии - ошибка
  PARAM_VALIDATE_JOB_EMPTY = 406 # Задача проверки топологии - пустое сообщение
  PARAM_VALIDATE_JOB_ABORT = 407 # Задача проверки топологии - отмена
  # Результаты
  PARAM_RESULT_ZIP_PATH = 500 # Архив с результатом

  belongs_to :operation_step
end
