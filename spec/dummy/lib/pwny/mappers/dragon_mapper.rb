module Pwny::Mappers
  module DragonMapperHooks
    class Base64EncodedAttributes64
      include Quiver::Mapper::Hook

      def before_hydrate(attributes)
        attributes[:secret] = Base64.decode64(attributes[:encrypted_secret]) if attributes[:encrypted_secret]

        attributes
      end

      def after_dehydrate(attributes)
        attributes[:encrypted_secret] = Base64.encode64(attributes.delete(:secret)) if attributes[:secret]

        attributes
      end
    end
  end

  class DragonMapper
    include Quiver::Mapper

    sorts :size

    type_attribute :type

    maps(
      classic_dragon: Pwny::Models::ClassicDragon,
      modern_dragon: Pwny::Models::ModernDragon
    )

    hooks(
      modern_dragon: [Pwny::Mappers::DragonMapperHooks::Base64EncodedAttributes64]
    )
  end
end
