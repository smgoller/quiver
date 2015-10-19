module Quiver
  class ErrorCollection
    include Enumerable

    def initialize(initial=nil)
      self.collection = []

      if initial
        initial.each do |e|
          raise ArgumentError, 'initial must be an array of Quiver::Errors' unless e.is_a?(Quiver::Error)
          collection << e
        end
      end
    end

    def errors
      collection.dup
    end

    def each
      collection.each do |e|
        yield e
      end
    end

    def <<(val)
      if val.is_a?(Quiver::Error)
        collection << val
      else
        raise ArgumentError, 'arg must be a Quiver::Error'
      end
    end

    def add(val)
      if val.is_a?(Quiver::ErrorCollection)
        collection.push(*val.errors)
      else
        raise ArgumentError, 'arg must be a Quiver::ErrorCollection'
      end
    end

    def +(val)
      raise ArgumentError, 'rval must be a Quiver::ErrorCollection' unless val.is_a?(Quiver::ErrorCollection)

      Quiver::ErrorCollection.new(collection + val.errors)
    end

    def success?
      !collection.any?
    end

    def ==(other)
      collection == other.send(:collection)
    end

    private

    attr_accessor :collection
  end
end
