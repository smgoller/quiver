module Quiver
  module Tasks
    def self.load_tasks
      if parent::Application.using_active_record
        include(::ActiveRecord::Tasks)
        load_active_record_tasks
      end
    end

    private

    def self.load_active_record_tasks
      load 'active_record/railties/databases.rake'

      database_tasks_constant = parent::Tasks::DatabaseTasks

      ::ActiveRecord::Base.schema_format = :ruby #configuration.schema_format
      database_tasks_constant.env = ENV['RACK_ENV'] #configuration.environment
      database_tasks_constant.seed_loader = "Later" #configuration.seed_loader

      database_configuration = YAML.load(ERB.new(File.read(File.join(parent::Application.app_root, 'config', 'database.yml'))).result)

      ::ActiveRecord::Base.configurations = database_tasks_constant.database_configuration = database_configuration

      database_tasks_constant.current_config = database_configuration[ENV['RACK_ENV']]
      database_tasks_constant.db_dir = File.join(parent::Application.app_root, 'db')
      database_tasks_constant.migrations_paths = File.join(parent::Application.app_root, 'db', 'migrate')
      database_tasks_constant.root = parent::Application.app_root
    end
  end
end
