module Quiver
  module Result
    attr_reader :object, :errors, :data

    def initialize(object=nil, errors=nil, data={})
      errors ||= Quiver::ErrorCollection.new

      if block_given?
        object = yield errors
      end

      self.object = object
      self.errors = errors
      self.data = data
    end

    def success?
      errors.success?
    end

    def when(success: nil, failure: nil)
      # one day if we ever have Ruby 2.1 we can delete this
      raise ArgumentError, 'missing keyword: success' if success == nil
      raise ArgumentError, 'missing keyword: failure' if failure == nil

      if success?
        success.call(object, self)
      else
        failure.call(errors, self)
      end
    end

    def ==(other)
      other.is_a?(Result) &&
      object == other.object &&
        errors == other.errors &&
        data == other.data
    end

    private

    attr_writer :object, :errors, :data
  end
end
