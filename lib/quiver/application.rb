module Quiver
  module Application
    def self.included(host)
      host.send(:extend, ClassMethods)

      host.root_module = host.parent
      host.root_module.const_set(:Adapters, Module.new)
      host.root_module.const_set(:Duties, Module.new)
      host.root_module.const_set(:Endpoints, Module.new)
      host.root_module.const_set(:Models, Module.new)
      host.root_module.const_set(:Mappers, Quiver::Mappers.dup)
      host.root_module.const_set(:Serializers, Module.new)
      host.root_module.const_set(:Tasks, Quiver::Tasks.dup)
      host.root_module.const_set(:Logger, Quiver::Logger.dup)
      host.root_module.const_set(:DutyMaster, Quiver::DutyMaster.dup)
      host.root_module.const_set(:DutyTestHelper, Quiver::DutyTestHelper.dup)
      host.memory_adapter_store = Quiver::Adapter::MemoryAdapterStore.new

      application_file = caller[0].partition(':').first
      host.app_root = File.expand_path('..', File.dirname(application_file))
      host.lib_dir = File.join(host.app_root, 'lib', File.basename(application_file, '.rb'))
      host.default_adapter_type = :memory
      host.default_duty_queue_backend = :memory
    end

    module ClassMethods
      attr_reader :app_root, :lib_dir, :root_module, :using_active_record,
        :using_delayed_job

      attr_accessor :memory_adapter_store, :default_adapter_type, :default_duty_queue_backend,
        :middleware_stack

      def app_root=(path)
        @app_root ||= path
      end

      def lib_dir=(path)
        @lib_dir ||= path
      end

      def root_module=(mod)
        @root_module ||= mod
      end

      def logger
        @logger ||= begin
          logger = root_module::Logger.new("log/logstash_#{ENV['RACK_ENV']}.log")
          logger.formatter = -> (severity, datetime, progname, msg) {
            "#{msg.to_json}\n"
          }
          logger
        end
      end

      def middleware_stack
        @middleware_stack ||= Quiver::MiddlewareStack.new
      end

      def load_everything!(extra_folders = [])
        load_env_vars!

        Dir[File.join(lib_dir, 'config', 'initializers', '**', '*.rb')].each { |f| require f}

        if !ENV["#{self.parents.first.to_s.underscore.upcase}_DOUBLE_MODE"]
          Dir[File.join(app_root, 'config', 'initializers', '**', '*.rb')].each { |f| require f}
        end

        require File.join(lib_dir, 'config', 'router')

        folders = ['models', 'mappers', 'adapters', 'serializers', 'endpoints', 'duties'] + extra_folders

        folders.each do |folder|
          Dir[File.join(lib_dir, folder, '*.rb')].each { |f| require f }
          Dir[File.join(lib_dir, folder, '**', '*.rb')].each { |f| require f }
        end
      end

      def use_active_record!(config_path = File.join(app_root, 'config', 'database.yml'))
        self.using_active_record = true
        require 'active_record'

        ActiveRecord::Base.configurations = YAML.load(ERB.new(File.read(config_path)).result)
        ActiveRecord::Base.establish_connection
      end

      def use_delayed_job!
        self.using_delayed_job = true
        require 'delayed_job_active_record'
      end

      private

      attr_writer :using_active_record, :using_delayed_job

      def load_env_vars!
        file_path = File.join(lib_dir, 'config', 'environment.yml')

        if File.exist?(file_path)
          require 'yaml'

          var_data = YAML.load(File.read(file_path))

          var_data.fetch(ENV['RACK_ENV'], {}).each do |k, v|
            ENV[k.upcase] ||= v.to_s unless v.is_a?(Hash)
          end

          var_data.each do |k, v|
            ENV[k.upcase] ||= v.to_s unless v.is_a?(Hash)
          end
        end
      end
    end

    attr_reader :router

    def initialize
      self.router = self.class.root_module::Config::Router.new
    end

    def call(env)
      self.class.middleware_stack.stack(router).call(env)
    end

    private

    attr_writer :router
  end
end
