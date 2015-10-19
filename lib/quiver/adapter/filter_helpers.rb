module Quiver
  module Adapter
    module FilterHelpers
      def initialize(memo, filter)
        self.memo = memo
        self.filter_params = filter
      end

      def filter
        filter_params.inject(memo) do |memo, (attr, filter)|
          filter_attributes = filter.is_a?(Hash) ? filter : filter.filter_attributes
          filter_attributes.inject(memo) do |memo, (comparator, value)|
            if value.nil?
              memo
            else
              case comparator.to_s.downcase
              when 'eq'
                equal_filter(memo, attr, value)
              when 'not_eq'
                not_equal_filter(memo, attr, value)
              when 'in'
                in_filter(memo, attr, value)
              when 'not_in'
                not_in_filter(memo, attr, value)
              when 'lt'
                less_than_filter(memo, attr, value)
              when 'gt'
                greater_than_filter(memo, attr, value)
              when 'lte'
                less_than_or_equal_filter(memo, attr, value)
              when 'gte'
                greater_than_or_equal_filter(memo, attr, value)
              when 'not_lt'
                greater_than_or_equal_filter(memo, attr, value)
              when 'not_gt'
                less_than_or_equal_filter(memo, attr, value)
              when 'not_lte'
                greater_than_filter(memo, attr, value)
              when 'not_gte'
                less_than_filter(memo, attr, value)
              else
                if respond_to?("#{comparator.to_s.downcase}_filter", true)
                  send("#{comparator.to_s.downcase}_filter", memo, attr, value)
                else
                  memo
                end
              end
            end
          end
        end
      end

      private

      attr_accessor :memo, :filter_params
    end
  end
end
