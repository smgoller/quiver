module Pwny::Endpoints
  module HelloWorld
    class Index
      include Lotus::Action

      def call(params)
        self.body = "Hello World, from Pwny"
      end
    end
  end
end
