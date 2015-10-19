require 'quiver/adapter/memory_adapter_filter'

module Quiver
  module Adapter
    module Memory
      include Quiver::Adapter::HelpersHelpers

      def self.included(host)
        super

        host.adapter_type(:memory)
        host.send(:extend, ClassMethods)
      end

      module ClassMethods
        def next_pk
          @pk_series ||= 0
          @pk_series += 1
        end
      end

      def find(primary_key)
        Quiver::Adapter::AdapterResult.new do |errors|
          if store.key?(primary_key)
            load_additional([store[primary_key].dup]).first
          else
            errors << Quiver::Mapper::NotFoundError.new('record', 'not_found')
            nil
          end
        end
      end

      def count
        count = stores.get(store_key).count

        Quiver::Adapter::AdapterResult.new(count)
      end

      def create(attributes, transaction)
        primary_key = new_primary_key

        if attributes[:__type__]
          attributes = attributes.merge(
            primary_key_name => primary_key,
            attributes[:__type__][:name] => attributes[:__type__][:value]
          )

          attributes.delete(:__type__)
        else
          attributes = attributes.merge(
            primary_key_name => primary_key
          )
        end

        store[primary_key] = attributes

        Quiver::Adapter::AdapterResult.new(attributes.dup)
      end

      def update(attributes, transaction)
        primary_key = attributes[primary_key_name]

        if attributes[:__type__]
          attributes = attributes.merge(
            attributes[:__type__][:name] => attributes[:__type__][:value]
          )

          attributes.delete(:__type__)
        end

        Quiver::Adapter::AdapterResult.new do |errors|
          if store.key?(primary_key)
            store[primary_key] = attributes.dup
          else
            errors << Quiver::Mapper::NotFoundError.new('record', 'does_not_exist')
            nil
          end
        end
      end

      def hard_delete(attributes, transaction)
        store = stores.get(store_key)

        Quiver::Adapter::AdapterResult.new do |errors|
          object = store.delete(attributes[primary_key_name])

          if object
            {}
          else
            errors << Quiver::Mapper::NotFoundError.new('record', 'not_found')
            nil
          end
        end
      end

      def query(q={})
        store = stores.get(store_key)

        filter_params = q[:filter] || {}
        sort_params = q[:sort] || {}
        pagination_params = q[:page] || {}

        objects = filter_klass.new(
          store.values,
          filter_params
        ).filter

        if sort_params.any?
          objects = objects.sort do |a, b|
            sort_params.reduce(0) do |memo, (attr, asc)|
              attr = attr.to_sym

              # A memo of 0 means either no sorting has happened yet,
              # or there has been a tie that might need breaking.
              if memo == 0
                sign = asc ? 1 : -1
                sign * (a[attr] <=> b[attr])
              else
                memo
              end
            end
          end
        end

        offset = pagination_params['offset'] || 0
        limit  = pagination_params['limit'] || -1
        total_count = objects.count

        if limit == -1
          range_end = -1
        else
          range_end = offset + limit - 1
        end
        objects = objects[offset..range_end]

        objects = load_additional(objects.map do |attrs|
          attrs.dup
        end)

        result = Quiver::Adapter::AdapterResult.new(objects)

        if pagination_params.any?
          result.data[:pagination_offset] = offset
          result.data[:pagination_limit] = limit
          result.data[:total_count] = total_count
        end

        result
      end

      private

      def stores
        @stores ||= self.class.parents[-2]::Application.memory_adapter_store
      end

      private

      def load_additional(items)
        items
      end

      def new_primary_key
        self.class.next_pk
      end

      def store_key
        mapper_name
      end

      def store
        stores.get(store_key.to_s)
      end

      def filter_klass
        Quiver::Adapter::MemoryAdapterFilter
      end
    end

    MemoryHelpers = Memory
  end
end
