module Quiver
  module Patcher
    def self.included(host)
      host.send(:include, AbstractAction)
      host.extend(ClassMethods)
    end

    module ClassMethods
      def values(&block)
        warn '`values` is no longer supported.'
      end

      def params(&block)
        klass = Class.new do
          include Lotus::Validations

          def self.param(name, options={}, &block)
            attribute(name, options, &block)
            nil
          end

          def self.build_validation_class(&block)
            kls = Class.new(self)
            kls.class_eval(&block)
            kls
          end

          def initialize(attributes)
            @raw_attributes = attributes
            super
          end

          def [](key)
            @attributes.get(key)
          end

          def to_h
            super.select do |key, _|
              @raw_attributes.to_h.has_key?(key.to_s) || @raw_attributes.to_h.has_key?(key.to_sym)
            end
          end
        end
        klass.instance_exec(&block)

        instance_variable_set('@params_attributes', klass)
      end

      def get_params_attributes_klass
        instance_variable_get('@params_attributes')
      end
    end

    attr_accessor :operation, :current_user

    def initialize(operation, extra_params)
      self.extra_params = extra_params || {}
      self.operation = operation
    end

    def run
      internal_call(nil)
    end

    def internal_call(_)
      serialize_with(action)
    end

    def params
      @params ||= begin
        if operation['value'].respond_to?(:to_h) && self.class.get_params_attributes_klass
          self.class.get_params_attributes_klass.new(extra_params.merge({data: operation['value'].to_h}))
        else
          extra_params.merge({data: operation['value']})
        end
      end
    end

    def serialize_with(data)
      self.class.serializer.new({collections: data}).serialize(context: self)
    end

    def request_path
      @request_path ||= operation['path']
    end

    def request_path_with_query
      request_path
    end

    private

    attr_accessor :extra_params
  end
end
