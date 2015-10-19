module Pwny::Adapters
  module PonyMapper
    class ActiveRecordAdapter
      include Quiver::Adapter::ActiveRecordHelpers

      primary_key_name :id

      define_record_class 'PonyRecord', table: 'ponies'
      use_record_class 'PonyRecord'

      private

      def filter_klass
        ActiveRecordAdapterFilter
      end

      class ActiveRecordAdapterFilter
        include Quiver::Adapter::ActiveRecordAdapterFilterDefaults

        def near_filter(memo, attr, value)
          memo.where("#{attr} >= ? AND #{attr} <= ?", value.to_i - 1, value.to_i + 1)
        end
      end
    end
  end
end
