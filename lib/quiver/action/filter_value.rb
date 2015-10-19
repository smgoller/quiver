module Quiver
  module Action
    module FilterValue
      PRESENCE = %w|nil not_nil|.freeze
      EQUALITIES = %w|eq not_eq|.freeze
      INCLUSIONS = %w|in not_in|.freeze
      INEQUALITIES = %w|gt lt gte lte not_gt not_lt not_gte not_lte|.freeze

      def self.with(type, *args, extras:[])
        set = Set.new(args + extras)
        klasses[[set, type]] ||= Class.new do
          include Extant::Attributes
          include FilterValue

          def self.supported_comparisons
            @supported_comparisons
          end

          def self.extra_supported_comparisons
            @extra_supported_comparisons
          end
        end.tap do |klass|
          klass.instance_variable_set(
            '@supported_comparisons',
            set
          )

          klass.instance_variable_set(
            '@extra_supported_comparisons',
            extras
          )

          extras.each do |extra|
            klass.send(:attribute, extra, type)
          end

          if set.include?(:presence)
            klass.send(:attribute, :nil, String)
            klass.send(:attribute, :not_nil, String)
          end

          if set.include?(:equalities)
            klass.send(:attribute, :eq, type)
            klass.send(:attribute, :not_eq, type)
          end

          if set.include?(:inclusions)
            klass.send(:attribute, :in, Array[type])
            klass.send(:attribute, :not_in, Array[type])
          end

          if set.include?(:inequalities)
            klass.send(:attribute, :gt, type)
            klass.send(:attribute, :not_gt, type)
            klass.send(:attribute, :gte, type)
            klass.send(:attribute, :not_gte, type)
            klass.send(:attribute, :lt, type)
            klass.send(:attribute, :not_lt, type)
            klass.send(:attribute, :lte, type)
            klass.send(:attribute, :not_lte, type)
          end
        end
      end

      def self.with_all(type, extras:[])
        with(type, :presence, :equalities, :inequalities, :inclusions)
      end

      def self.klasses
        @klasses ||= {}
      end

      attr_reader :errors

      def initialize(filter)
        self.errors = Quiver::ErrorCollection.new

        filter = filter.to_h if filter.is_a?(Lotus::Utils::Hash)
        self.filter = filter

        if filter.is_a?(Hash)
          keys = filter.keys
          keys.each do |key|
            filter[key.sub('~', 'not_')] = filter.delete(key)
          end

          keys.each do |key|
            if INCLUSIONS.include?(key) && !filter[key].is_a?(Array)
              errors << FilterError.new("'#{key}' must map to an Array")
              filter[key] = []
            end
          end

          (filter.keys - supported_comparisons).each do |key|
            errors << FilterError.new("'#{key}' is not supported")
            filter.delete(key)
          end

          filter
        else
          filter = {}
          errors << FilterError.new('filters must be a Hash')
        end

        super

        validate
      end

      def filter_attributes
        attributes.slice(*filter.keys.map(&:to_sym))
      end

      def valid?
        !errors.any?
      end

      private

      attr_writer :errors
      attr_accessor :filter

      def validate
        extant_attributes.each do |key, attr_object|
          if attr_object.set? && !attr_object.coerced?
            case
            when EQUALITIES.include?(attr_object.name.to_s) || INEQUALITIES.include?(attr_object.name.to_s) || PRESENCE.include?(attr_object.name.to_s)
              errors << FilterError.new("'#{attr_object.name}' must not map to Hashes or Arrays")
            when INCLUSIONS.include?(attr_object.name.to_s)
              errors << FilterError.new("'#{attr_object.name}' must map to an Array")
            end
          end
        end
      end

      def supported_comparisons
        unless @supported_comparisons
          @supported_comparisons = []
          @supported_comparisons += PRESENCE if self.class.supported_comparisons.include?(:presence)
          @supported_comparisons += EQUALITIES if self.class.supported_comparisons.include?(:equalities)
          @supported_comparisons += INEQUALITIES if self.class.supported_comparisons.include?(:inequalities)
          @supported_comparisons += INCLUSIONS if self.class.supported_comparisons.include?(:inclusions)
          @supported_comparisons += self.class.extra_supported_comparisons.map(&:to_s)
        end

        @supported_comparisons
      end
    end
  end
end

require 'quiver/action/filter_error'
