module Quiver
  module Adapter
    module ActiveRecordAdapterFilterDefaults
      include FilterHelpers

      def self.included(host)
        host.extend(ClassMethods)
      end

      module ClassMethods
        def find(attr_name, opts)
          raise ArgumentError, ':on must be a table name specified as a symbol' unless opts[:on].is_a?(Symbol)
          # in the future we want to support arrays, but right now we don't need
          # it so it is hard to justify the extra time it would take
          #
          # tables = opts[:on].is_a?(Array) ? opts[:on] : [opts[:on]]
          attr_lookup_table[attr_name.to_sym] = opts[:on]
        end

        private

        def attr_lookup_table
          @attr_lookup_table ||= {}
        end
      end

      def equal_filter(memo, attr, value)
        memo.where(hash_style_attr(attr, value))
      end

      def not_equal_filter(memo, attr, value)
        memo.where.not(hash_style_attr(attr, value))
      end

      def in_filter(memo, attr, value)
        memo.where(hash_style_attr(attr, value))
      end

      def not_in_filter(memo, attr, value)
        memo.where.not(hash_style_attr(attr, value))
      end

      def less_than_filter(memo, attr, value)
        memo.where("#{string_style_attr(attr)} < ?", value)
      end

      def greater_than_filter(memo, attr, value)
        memo.where("#{string_style_attr(attr)} > ?", value)
      end

      def less_than_or_equal_filter(memo, attr, value)
        memo.where("#{string_style_attr(attr)} <= ?", value)
      end

      def greater_than_or_equal_filter(memo, attr, value)
        memo.where("#{string_style_attr(attr)} >= ?", value)
      end

      def nil_filter(memo, attr, value)
        if value == 'true' || value == true
          memo.where("#{string_style_attr(attr)} IS NULL")
        else
          memo.where("#{string_style_attr(attr)} IS NOT NULL")
        end
      end

      def not_nil_filter(memo, attr, value)
        if value == 'true' || value == true
          memo.where("#{string_style_attr(attr)} IS NOT NULL")
        else
          memo.where("#{string_style_attr(attr)} IS NULL")
        end
      end

      private

      def attr_lookup(attr)
        self.class.send(:attr_lookup_table)[attr]
      end

      def hash_style_attr(attr, value)
        if table = attr_lookup(attr)
          {table => {attr => value}}
        else
          {attr => value}
        end
      end

      def string_style_attr(attr)
        if table = attr_lookup(attr)
          "#{table}.#{attr}"
        else
          attr
        end
      end
    end

    class ActiveRecordAdapterFilter
      include ActiveRecordAdapterFilterDefaults
    end
  end
end
