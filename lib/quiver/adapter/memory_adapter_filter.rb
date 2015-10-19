module Quiver
  module Adapter
    module MemoryAdapterFilterDefaults
      include FilterHelpers

      def equal_filter(memo, attr, value)
        memo.select do |obj|
          obj[attr.to_sym] == value
        end
      end

      def not_equal_filter(memo, attr, value)
        memo.select do |obj|
          obj[attr.to_sym] != value
        end
      end

      def in_filter(memo, attr, value)
        memo.select do |obj|
          value.include?(obj[attr.to_sym])
        end
      end

      def not_in_filter(memo, attr, value)
        memo.select do |obj|
          !value.include?(obj[attr.to_sym])
        end
      end

      def less_than_filter(memo, attr, value)
        memo.select do |obj|
          obj[attr.to_sym] < value
        end
      end

      def greater_than_filter(memo, attr, value)
        memo.select do |obj|
          obj[attr.to_sym] > value
        end
      end

      def less_than_or_equal_filter(memo, attr, value)
        memo.select do |obj|
          obj[attr.to_sym] <= value
        end
      end

      def greater_than_or_equal_filter(memo, attr, value)
        memo.select do |obj|
          obj[attr.to_sym] >= value
        end
      end

      def nil_filter(memo, attr, value)
        memo.select do |obj|
          obj[attr.to_sym].nil? == (value == 'true' || value == true)
        end
      end

      def not_nil_filter(memo, attr, value)
        memo.select do |obj|
          obj[attr.to_sym].nil? != (value == 'true' || value == true)
        end
      end
    end

    class MemoryAdapterFilter
      include MemoryAdapterFilterDefaults
    end
  end
end
