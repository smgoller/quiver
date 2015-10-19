module Pwny::Endpoints
  module HelloWorld
    class Post
      include Quiver::Action

      serializer Pwny::Serializers::PonySerializer

      params do
        param :blah
      end

      def action
      end
    end
  end
end
