module Quiver
  module Duty
    attr_reader :arguments

    def self.included(host)
      host.send(:prepend, PrependMethods)
    end

    def initialize(*args)
      self.arguments = args
    end

    def perform(*args)
      raise NotImplementedError, 'Duties must implement #perform'
    end

    module PrependMethods
      def perform(*args)
        super
      rescue => e
        handle_error(e) if respond_to?(:handle_error, true)
        raise
      ensure
        if self.class.parents[-2]::Application.using_active_record
          ActiveRecord::Base.clear_active_connections!
        end
      end
    end

    private

    attr_writer :arguments
  end
end
