require_relative 'job'

module Pwny::Models
  class ModernDragon
    include Quiver::Model

    # shared
    attribute :id, Integer
    attribute :name, String
    attribute :color, String
    attribute :size, Integer

    # specific
    attribute :twitter_followers, String # comma separated
    attribute :jobs, Array[JobCoercer]

    attribute :secret, String

    def type
      :modern_dragon
    end
  end
end
