module Quiver::Mapper
  class NotFoundError < Quiver::Error
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
      404
    end

    def code
      :not_found_error
    end

    def serialization_type
      'Error'
    end
  end
end
