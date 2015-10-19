module Quiver
  class DutyTestHelper
    class MemoryHelper
      def carry_out(count)
        count.times do
          duty_data = Quiver::DutyMaster::MemoryAdapter.queue_array.shift
          next unless duty_data

          duty = duty_data[:duty_class].new(*duty_data[:arguments])
          duty.perform
        end
      end
    end
  end
end
