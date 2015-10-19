module Quiver
  class DutyTestHelper
    class DelayedJobHelper
      def carry_out(count)
        Delayed::Worker.new.work_off(count)
      end
    end
  end
end
