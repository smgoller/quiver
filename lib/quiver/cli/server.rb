require 'rack'

module Quiver
  module CLI
    class Server < ::Rack::Server
      DEFAULT_OPTIONS = {
        config: 'config.ru',
        Port: '3000',
        Host: '127.0.0.1',
        AccessLog: []
      }

      def initialize(options = {})
        @quiver_opts = options
        @options = DEFAULT_OPTIONS.merge(rack_options)

        if reloading_code?
          require 'shotgun'
          @app  = Shotgun::Loader.new(@options[:config])
        end
      end

      private

      def reloading_code?
        @quiver_opts[:reloading_code] || false
      end

      def rack_options
        {}.tap do |h|
          h[:Host] = @quiver_opts[:host] if @quiver_opts[:host]
          h[:Port] = @quiver_opts[:port] if @quiver_opts[:port]
        end
      end
    end
  end
end
