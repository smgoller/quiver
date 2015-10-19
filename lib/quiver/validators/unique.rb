require 'quiver/action/filter_value'

module Quiver
  module Validators
    class Unique < Base
      def validate
        errors = Quiver::ErrorCollection.new

        result = mapper.send(:query,
          filter: {
            name => {'eq' => value}
          }
        )

        if result.object.any?
          unless result.object.size == 1 &&
            result.object.first.send(adapter.class.primary_key_name) == model.send(adapter.class.primary_key_name)

            errors << Quiver::Model::ValidationError.new(name, must_be_unique)
          end
        end

        errors
      end

      private

      def must_be_unique
        'must_be_unique'
      end
    end
  end
end
