module Pwny::Models
  class Job
    include Quiver::Model

    attribute :id, Integer
    attribute :position, String
    attribute :company_name, String
  end

  class JobCoercer < Extant::Coercers::Base
    def coerce
      if value.is_a?(Job)
        self.coerced = true
        value
      elsif value.is_a?(Hash)
        begin
          result = Job.new(value)
          self.coerced = true
          result
        rescue
          UncoercedValue
        end
      else
        UncoercedValue
      end
    end
  end
end
