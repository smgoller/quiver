module Quiver
  class DutyMaster
    def initialize
      self.adapter = adapter_class.new
    end

    def queue(duty)
      adapter.queue(duty.class, duty.arguments)
    end

    private

    attr_accessor :adapter

    def adapter_class
      adapter_type = self.class.parents[-2]::Application.default_duty_queue_backend
      self.class.const_get(adapter_type.to_s.camelize + 'Adapter')
    end
  end
end

require 'quiver/duty_master/memory_adapter'
require 'quiver/duty_master/delayed_job_adapter'
