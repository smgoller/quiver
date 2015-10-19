module Pwny::Mappers
  class PonyMapper
    include Quiver::Mapper

    maps Pwny::Models::Pony

    sorts :mane_length, :color

    default_filter({
      deleted_at: {
        nil: true
      }
    })
  end
end
