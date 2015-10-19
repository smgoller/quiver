module Quiver
  class DutyMaster
    class MemoryAdapter
      class << self
        def queue_array
          @queue_array ||= []
        end
      end

      def queue(duty_class, arguments)
        self.class.queue_array << {
          duty_class: duty_class,
          arguments: arguments
        }
      end
    end
  end
end
