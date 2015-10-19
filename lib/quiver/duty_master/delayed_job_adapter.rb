module Quiver
  class DutyMaster
    class DelayedJobAdapter
      WrapperClass = Struct.new(:duty_class, :arguments) do
        def perform
          duty_class.new(*arguments).perform
        end
      end

      def queue(duty_class, arguments)
        Delayed::Job.enqueue WrapperClass.new(duty_class, arguments)
      end
    end
  end
end
