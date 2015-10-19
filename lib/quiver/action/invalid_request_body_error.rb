module Quiver::Action
  class InvalidRequestBodyError < Quiver::Error
    def initialize
    end

    def title
      'invalid_request_body'
    end

    def detail
      'request body must be valid json'
    end

    def path
      "/"
    end

    def status
      400
    end

    def code
      :invalid_request_body
    end

    def serialization_type
      'Error'
    end
  end
end
