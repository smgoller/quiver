module Quiver
  class DutyTestHelper
    def initialize
      self.adapter = helper_class.new
    end

    def carry_out(count)
      adapter.carry_out(count)
    end

    private

    attr_accessor :adapter

    def helper_class
      adapter_type = self.class.parents[-2]::Application.default_duty_queue_backend
      self.class.const_get(adapter_type.to_s.camelize + 'Helper')
    end
  end
end

require 'quiver/duty_test_helper/memory_helper'
require 'quiver/duty_test_helper/delayed_job_helper'
