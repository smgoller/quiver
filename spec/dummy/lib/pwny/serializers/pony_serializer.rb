module Pwny::Serializers
  class PonySerializer
    include Quiver::Serialization::JsonApi::Serializer

    for_type 'Pony' do
      attribute :id
      attributes :name, :mane_length, :color
    end
  end
end
