module Quiver
  class MiddlewareStack
    attr_reader :middlewares

    def initialize
      self.middlewares = []
    end

    def <<(middleware)
      middlewares << middleware
      @middleware_stack = nil
      middlewares
    end

    def unshift(*middleware)
      middlewares.unshift(*middleware)
      @middleware_stack = nil
      middlewares
    end

    def stack(app)
      @stack ||= rebuild_stack!(app)
    end

    private

    attr_writer :middlewares

    def rebuild_stack!(app)
      middlewares.reverse.inject(app) do |app, middleware|
        middleware.new(app)
      end
    end
  end
end
