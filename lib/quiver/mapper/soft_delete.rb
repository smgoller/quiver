module Quiver
  module Mapper
    module SoftDelete
      def soft_delete(model)
        model.deleted_at = Time.now
        save(model)
      end

      def restore(model)
        model.deleted_at = nil
        save(model)
      end
    end
  end
end
