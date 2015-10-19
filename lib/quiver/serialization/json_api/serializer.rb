module Quiver::Serialization
  module JsonApi
    module Serializer
      def self.included(base)
        base.send(:extend, ClassMethods)
      end

      attr_accessor :collection_info

      def initialize(collection_info)
        self.collection_info = collection_info
      end

      def serialize(opts={})
        output = {}

        [:data, :linked, :errors].each do |type|
          if collection = fetch_collection(type)
            output[type] = serialize_items(collection, opts)
          end
        end

        output
      end

      private

      def fetch_collection(key)
        collection_info[:collections][key]
      end

      def serialize_items(items, opts)
        items.map do |item|
          serialization_type = if item.respond_to?(:serialization_type)
            item.serialization_type
          else
            item.class.name
          end

          if handler = self.class.type_handlers[serialization_type]
            handler.serialize(item, opts).merge(
              type: serialization_type.underscore.pluralize
            )
          end
        end.compact
      end

      module ClassMethods
        def self.extended(base)
          base.instance_variable_set('@type_handlers', {})

          begin
            base.for_type 'Error', JsonApi::ItemTypeHandler.new('Error', -> {
              attributes :title, :detail, :path, :code
              calculated_attribute(:status) { |item| item.status.to_s }
            }, true)
          rescue JsonApi::NoIdError
          end
        end

        attr_accessor :type_handlers

        def for_type(type, handler=nil, &block)
          if handler
            type_handlers[type] = handler
          else
            type_handlers[type] = JsonApi::ItemTypeHandler.new(type, block)
          end
        end

        def type_handlers
          instance_variable_get('@type_handlers')
        end
      end
    end
  end
end
