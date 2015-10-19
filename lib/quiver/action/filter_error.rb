module Quiver::Action
  class FilterError < Quiver::Error
    attr_reader :detail

    def initialize(detail)
      self.detail = detail
    end

    def title
      'filter_error'
    end

    def path
      "/"
    end

    def status
      422
    end

    def code
      :filter_error
    end

    def serialization_type
      'Error'
    end

    private

    attr_writer :detail
  end
end
