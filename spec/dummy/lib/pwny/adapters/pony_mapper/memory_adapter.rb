module Pwny::Adapters
  module PonyMapper
    class MemoryAdapter
      include Quiver::Adapter::MemoryHelpers

      primary_key_name :id

      private

      def filter_klass
        MemoryAdapterFilter
      end

      class MemoryAdapterFilter
        include Quiver::Adapter::MemoryAdapterFilterDefaults

        def near_filter(memo, attr, value)
          memo.select do |obj|
            (value.to_i-1..value.to_i+1).include?(obj[attr.to_sym])
          end
        end
      end
    end
  end
end
