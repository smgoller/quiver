module Pwny::Models
  class Pony
    include Quiver::Model
    include Quiver::Model::SoftDelete

    attribute :id, Integer
    attribute :name, String
    attribute :color, String
    attribute :mane_length, Integer
    attribute :unicorn, Boolean
    attribute :pegasus, Boolean
    attribute :reputation, Integer, default: 0
    attribute :unique_id, Integer

    attribute :created_at, Time
    attribute :updated_at, Time
    attribute :deleted_at, Time

    validate -> (obj) {
      errors = Quiver::ErrorCollection.new

      if obj.alicorn?
        if !obj.mane_length || obj.mane_length < 30
          errors << Quiver::Error.new(
            :mane_length,
            'must_be_over_30_inches_on_alicorns'
          )
        end
      end

      errors
    }

    validate :unique_id, unique: true

    def alicorn?
      unicorn && pegasus
    end
  end
end
