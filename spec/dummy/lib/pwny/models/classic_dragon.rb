require_relative 'job'

module Pwny::Models
  class ClassicDragon
    include Quiver::Model

    # shared
    attribute :id, Integer
    attribute :name, String
    attribute :color, String
    attribute :size, Integer

    # specific
    attribute :gold_count, Integer
    attribute :piles_of_bones, Integer

    def type
      :classic_dragon
    end
  end
end
