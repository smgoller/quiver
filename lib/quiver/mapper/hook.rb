module Quiver
  module Mapper
    module Hook
      def before_hydrate(attributes)
        attributes
      end

      def after_dehydrate(attributes)
        attributes
      end

      def before_save(model)
        model
      end

      def after_save(result)
        result
      end
    end
  end
end
