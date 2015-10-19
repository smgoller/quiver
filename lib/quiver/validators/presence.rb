module Quiver
  module Validators
    class Presence < Base
      def validate
        error_collection = Quiver::ErrorCollection.new

        # if options is true
        # then the value must be non-nil
        # otherwise it must be nil
        if options
          if value == nil
            error_collection << Quiver::Model::ValidationError.new(name, failed_presence_type)
          end
        else
          if value != nil
            error_collection << Quiver::Model::ValidationError.new(name, failed_non_presence_type)
          end
        end

        error_collection
      end

      private

      def failed_presence_type
        "should_be_present"
      end

      def failed_non_presence_type
        "should_not_be_present"
      end
    end
  end
end
