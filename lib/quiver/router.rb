module Quiver
  module Router
    def self.included(host)
      host.send(:extend, ClassMethods)
    end

    module ClassMethods
      def routes(&block)
        @routes_block = block
      end

      def routes_block
        @routes_block || Proc.new {}
      end
    end

    def initialize
      resolver = Lotus::Routing::EndpointResolver.new(pattern: %Q|#{root_module}::Endpoints::%{controller}::%{action}|)
      self.router = Lotus::Router.new(resolver: resolver, parsers: [JsonParser.new], &self.class.routes_block)
      router.get('/', to: ->(env) { [200, {}, ["#{root_module} is now flying out of the Quiver!"]] })
    end

    def call(env)
      router.call(env)
    end

    private

    attr_accessor :router

    def root_module
      self.class.parents[1].name
    end
  end
end

require 'quiver/route_helper'
