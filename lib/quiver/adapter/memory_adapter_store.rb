module Quiver
  module Adapter
    class MemoryAdapterStore
      def initialize
        clean!
      end

      def clean!
        self.store = {}
      end

      def get(key)
        store[key] ||= {}
      end

      def transaction(&block)
        pristine_store = store.deep_dup

        begin
          yield block
        rescue Quiver::Mappers::RollbackTransaction
          self.store = pristine_store
        rescue => ex
          self.store = pristine_store
          raise ex
        end
      end

      private

      attr_accessor :store
    end
  end
end
