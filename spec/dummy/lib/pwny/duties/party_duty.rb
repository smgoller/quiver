module Pwny::Duties
  class PartyDuty
    include Quiver::Duty

    attr_accessor :organizer_id, :reason, :rsvp_count

    def initialize(organizer_id, reason, rsvp_count)
      raise ArgumentError if rsvp_count < 0
      self.organizer_id = organizer_id
      self.reason = reason
      self.rsvp_count = rsvp_count
      super
    end

    def perform
      result = Pwny::Mappers::PonyMapper.new.find(organizer_id)

      if result.success?
        pony = result.object
        pony = pony.with(reputation: pony.reputation + rsvp_count)
        result = Pwny::Mappers::PonyMapper.new.save(pony)
      end
    end
  end
end
