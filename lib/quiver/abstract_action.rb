module Quiver
  module AbstractAction
    def self.included(host)
      host.send(:include, Lotus::Action)
      host.extend(ClassMethods)
    end

    module ClassMethods
      def serializer(val = nil)
        if val
          @serializer = val
        else
          @serializer || raise("#{self.name} serializer not set")
        end
      end
    end

    def call(params)
      # because ruby < 2.2.0, pry, and Module.prepend aren't friends
      internal_call(params)
    end

    def arrayify(arg)
      if arg.is_a?(Array)
        arg
      else
        [arg]
      end
    end
  end
end
