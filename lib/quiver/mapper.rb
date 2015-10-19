module Quiver
  module Mapper
    def self.included(host)
      host.send(:extend, ClassMethods)
    end

    module ClassMethods
      def type_attribute(attr_name=nil)
        if attr_name
          @type_attribute = attr_name
        end

        @type_attribute
      end

      private

      def filters(*args)
        raise 'Mapper.filters is unused, it should be removed'
      end

      def default_filter(h=nil)
        if h
          h.each do |k, v|
            v.each do |comparator, _|
              unless %i|nil not_nil ~nil|.include?(comparator)
                raise 'Default filter only supports the nil and ~nil comparators'
              end
            end
          end

          @default_filter = h
        end

        @default_filter || {}
      end

      def sorts(*args)
        @sorts ||= []

        if args.any?
          @sorts += args.map(&:to_sym)
        end

        @sorts.dup.freeze
      end

      def maps(model_klass=nil)
        if model_klass
          @maps = model_klass
        end

        @maps
      end

      def hooks(hook_array=nil)
        if hook_array
          @hooks = hook_array
        end

        @hooks
      end

      def adapter_for(adapter_type)
        raise ArgumentError, 'adapter_type must not be nil' if adapter_type.nil?
        unnamespaced_name = name.split('::').last
        adapters_namespace = self.parents[-2]::Adapters.const_get(unnamespaced_name)
        adapters_namespace.const_get(adapter_type.to_s.camelize + 'Adapter')
      end
    end

    def initialize(adapter_type=nil)
      adapter_type ||= self.class.parents[-2]::Application.default_adapter_type
      self.adapter_type = adapter_type
      self.adapter = self.class.send(:adapter_for, adapter_type).new
    end

    def save(model)
      self.class.parents[-2]::Mappers.transaction do |transaction|
        hooks = self.class.send(:hooks) || []

        if self.class.type_attribute
          type_key = model.send(self.class.type_attribute)
        end

        if hooks.is_a?(Hash)
          hooks = hooks[type_key.to_sym] || []
        end

        hooks = hooks.map(&:new)

        model = hooks.inject(model) do |model, hook|
          hook.before_save(model)
        end

        if model.persisted_by.include?(adapter_type)
          result = update(model, transaction)
        else
          result = create(model, transaction)

          if result.success?
            # model.persisted_by!(adapter_type)
          end
        end

        hooks.inject(result) do |result, hook|
          hook.after_save(result)
        end
      end
    end

    def find(pk)
      adapter.find(pk).when(
        success: -> (attributes, result) {
          Quiver::Mapper::MapperResult.new { |e| hydrate(attributes) }
        },
        failure: -> (errors, result) { result }
      )
    end

    def all
      query({})
    end

    def hard_delete(model)
      self.class.parents[-2]::Mappers.transaction do |transaction|
        attributes = dehydrate(model)

        Quiver::Mapper::MapperResult.new(nil, nil, {adapter_op: :hard_delete}) do |errors|
          adapter.hard_delete(attributes, transaction).when(
            success: -> (attributes, result) {
              {}
            },
            failure: -> (adapter_errors, result) { errors.add(adapter_errors); nil }
          )
        end
      end
    end

    def soft_delete(model)
      self.class.parents[-2]::Mappers.transaction do |transaction|
        model.deleted_at = Time.now

        attributes = dehydrate(model)

        Quiver::Mapper::MapperResult.new(nil, nil, {adapter_op: :soft_delete}) do |errors|
          adapter.update(attributes, transaction).when(
            success: -> (attributes, result) {
              hydrate(attributes)
            },
            failure: -> (adapter_errors, result) { errors.add(adapter_errors); nil }
          )
        end
      end
    end

    def restore(model)
      self.class.parents[-2]::Mappers.transaction do |transaction|
        model.deleted_at = nil

        attributes = dehydrate(model)

        Quiver::Mapper::MapperResult.new(nil, nil, {adapter_op: :restore}) do |errors|
          adapter.update(attributes, transaction).when(
            success: -> (attributes, result) {
              hydrate(attributes)
            },
            failure: -> (adapter_errors, result) { errors.add(adapter_errors); nil }
          )
        end
      end
    end

    def count
      adapter.count
    end

    def filter(params)
      SimpleQueryBuilder.new(self).filter(params)
    end

    def sort(params)
      SimpleQueryBuilder.new(self).sort(params)
    end

    def paginate(params)
      SimpleQueryBuilder.new(self).paginate(params)
    end

    private

    attr_accessor :adapter, :adapter_type

    def when_valid(model, adapter_op)
      raise ArgumentError, "requires block" unless block_given?

      errors = model.validate(
        tags: [adapter_op],
        mapper: self,
        model: model
      )

      if errors.success?
        current_time = Time.now.utc
        model.updated_at = current_time if model.respond_to?(:updated_at=)

        if adapter_op == :create
          model.created_at ||= current_time if model.respond_to?(:created_at)
        end

        object = yield(model, errors)
      end

      Quiver::Mapper::MapperResult.new(object, errors, adapter_op: adapter_op)
    end

    def create(model, transaction)
      when_valid(model, :create) do |model, errors|
        attributes = dehydrate(model)

        adapter.create(attributes, transaction).when({
          success: -> (attributes, result) {
            model.persisted_by!(adapter_type)
            model.send(:"#{adapter.send(:primary_key_name)}=", attributes[adapter.send(:primary_key_name)])
            hydrate(attributes)
          },
          failure: -> (adapter_errors, result) { errors.add(adapter_errors) }
        })
      end
    end

    def update(model, transaction)
      when_valid(model, :update) do |model, errors|
        attributes = dehydrate(model)

        adapter.update(attributes, transaction).when(
          success: -> (attributes, result) {
            hydrate(attributes)
          },
          failure: -> (adapter_errors, result) { errors.add(adapter_errors); nil }
        )
      end
    end

    def query(q={})
      adapter.query(q).when(
        success: -> (items, result) {
          Quiver::Mapper::MapperResult.new(nil, nil, result.data) { |e|
            items.map do |attributes|
              hydrate(attributes)
            end
          }
        },
        failure: -> (errors, result) { result }
      )
      end

    def hydrate(attributes)
      attributes = attributes.dup

      hooks = self.class.send(:hooks) || []

      type_key = attributes.delete(self.class.type_attribute) || attributes.delete(self.class.type_attribute.to_s)

      if hooks.is_a?(Hash)
        hooks = hooks[type_key.to_sym] || []
      end

      attributes = hooks.inject(attributes) do |attrs, hook|
        hook.new.before_hydrate(attrs)
      end

      if self.class.send(:maps).is_a?(Hash)
        object = self.class.send(:maps)[type_key.to_sym].new(attributes)
      else
        object = self.class.send(:maps).new(attributes)
      end

      object.persisted_by!(adapter_type)

      object
    end

    def dehydrate(model)
      attributes = model.attributes

      if self.class.type_attribute
        attributes = attributes.merge(:__type__ => {
          value: model.send(self.class.type_attribute),
          name: self.class.type_attribute
        })
      end

      hooks = self.class.send(:hooks) || []

      if hooks.is_a?(Hash)
        hooks = hooks[model.send(self.class.type_attribute)] || []
      end

      hooks.inject(attributes) do |attrs, hook|
        hook.new.after_dehydrate(attrs)
      end
    end
  end
end

require 'quiver/mapper/mapper_result'
require 'quiver/mapper/not_found_error'
require 'quiver/mapper/simple_query_builder'
require 'quiver/mapper/soft_delete'
require 'quiver/mapper/hook'
