module Quiver
  module Validators
    class Base
      def initialize(value, options, name, mapper=nil, model=nil)
        self.value = value
        self.options = options
        self.name = name
        self.mapper = mapper
        self.model = model
      end

      private

      attr_accessor :value, :options, :name, :mapper, :model

      def adapter
        mapper.send(:adapter)
      end
    end
  end
end
