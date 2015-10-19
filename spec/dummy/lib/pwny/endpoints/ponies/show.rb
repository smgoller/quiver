module Pwny::Endpoints
  module Ponies
    class Show
      include Quiver::Action

      serializer Pwny::Serializers::PonySerializer

      def action
        Pwny::Mappers::PonyMapper.new.find(params[:id])
      end
    end
  end
end
