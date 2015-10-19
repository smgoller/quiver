module Quiver::Model
  class ValidationError < Quiver::Error
    def title
      type
    end

    def detail
      type
    end

    def path
      "/#{subject}"
    end

    def status
      422
    end

    def code
      :model_validation_error
    end

    def serialization_type
      'Error'
    end
  end
end
