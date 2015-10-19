require 'logger'

module Quiver
  class Logger < ::Logger
    def initialize(logdev, shift_age = 0, shift_size = 1048576)
      @progname = nil
      @level = DEBUG
      @default_formatter = Formatter.new
      @formatter = nil
      @logdev = nil

      if logdev
        @logdev = LogDevice.new(
          logdev,
          :shift_age => shift_age,
          :shift_size => shift_size
        )
      end
    end

    class LogDevice < ::Logger::LogDevice
      def add_log_header(file)
      end
    end
  end
end
