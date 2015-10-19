require 'quiver/adapter/active_record_adapter_filter'
require 'quiver/adapter/arec_low_level_creator'
require 'quiver/adapter/arec_low_level_updater'
require 'quiver/adapter/arec_low_level_deleter'
require 'quiver/mappers'

module Quiver
  module Adapter
    module ActiveRecord
      include Quiver::Adapter::HelpersHelpers

      def self.included(host)
        super

        host.adapter_type(:active_record)
        host.send(:extend, ClassMethods)
      end

      module ClassMethods
        def define_record_class(name, options)
          return if !self.parents[-2]::Application.using_active_record

          table_name = options.fetch(:table)

          record_classes[name] = Class.new(::ActiveRecord::Base) do
            self.table_name = table_name
            self.inheritance_column = 'a_name_that_will_never_be_used'

            def self.name=(val)
              @reported_name = val
            end

            def self.name
              @reported_name
            end
          end.tap do |klass|
            klass.name = name
          end
        end

        def record_classes
          @record_classes ||= {}
        end

        def use_record_class(val=nil)
          if val
            @use_record_class = val
          end

          @use_record_class
        end
      end

      def find(primary_key)
        Quiver::Adapter::AdapterResult.new do |errors|
          if record = base_query.find_by(primary_key_name => primary_key)
            load_additional([record.attributes.symbolize_keys]).first
          else
            errors << Quiver::Mapper::NotFoundError.new('record', 'not_found')
            nil
          end
        end
      end

      def count
        count = default_record_class.count

        Quiver::Adapter::AdapterResult.new(count)
      end

      def create(attributes, transaction)
        persister = ARecLowLevelCreator.new(self.class, attributes)

        if attributes[:__type__]
          attributes = attributes.merge(
            attributes[:__type__][:name] => attributes[:__type__][:value]
          )

          attributes.delete(:__type__)
        end

        begin
          create_mappings(attributes, persister)
        rescue ::ActiveRecord::ActiveRecordError
          transaction.rollback!
          persister.failed!
        end

        Quiver::Adapter::AdapterResult.new do |errors|
          if persister.success?
            persister.result
          else
            errors << Quiver::Error.new('record', 'not_persisted')
            nil
          end
        end
      end

      def update(attributes, transaction)
        persister = ARecLowLevelUpdater.new(self.class, attributes)

        if attributes[:__type__]
          attributes = attributes.merge(
            attributes[:__type__][:name] => attributes[:__type__][:value]
          )

          attributes.delete(:__type__)
        end

        begin
          update_mappings(attributes, persister)
        rescue ::ActiveRecord::ActiveRecordError
          transaction.rollback!
          persister.failed!
        end

        Quiver::Adapter::AdapterResult.new do |errors|
          if persister.success?
            persister.result
          else
            errors << Quiver::Error.new('record', 'not_updated')
            nil
          end
        end
      end

      def hard_delete(attributes, transaction)
        unpersister = ARecLowLevelDeleter.new(self.class, attributes)

        if attributes[:__type__]
          attributes = attributes.merge(
            attributes[:__type__][:name] => attributes[:__type__][:value]
          )

          attributes.delete(:__type__)
        end

        begin
          delete_mappings(attributes, unpersister)
        rescue ::ActiveRecord::ActiveRecordError
          transaction.rollback!
          unpersister.failed!
        end

        Quiver::Adapter::AdapterResult.new do |errors|
          if unpersister.success?
            {}
          else
            errors << Quiver::Error.new('record', 'not_deleted')
            nil
          end
        end
      end

      def query(q={})
        filter_params = q[:filter] || {}
        sort_params = q[:sort] || {}
        pagination_params = q[:page] || {}

        query = filter_klass.new(
          base_query,
          filter_params
        ).filter

        count_query = filter_klass.new(
          base_count_query,
          filter_params
        ).filter

        sort_params.each do |attr, asc|
          order = asc ? 'ASC' : 'DESC'
          query = query.order("#{attr} #{order}")
          count_query = count_query.order("#{attr} #{order}")
        end

        total_count = count_query.count

        if pagination_params['limit'] && pagination_params['limit'] != -1
          query = query.limit(pagination_params['limit'])
        end

        if pagination_params['offset']
          query = query.offset(pagination_params['offset'])
        end

        objects = load_additional(query.map(&:attributes).map(&:symbolize_keys))
        result = Quiver::Adapter::AdapterResult.new(objects)

        if pagination_params.any?
          result.data[:pagination_offset] = pagination_params['offset'] || 0
          result.data[:pagination_limit] = pagination_params['limit'] || -1
          result.data[:total_count] = total_count
        end

        result
      end

      private

      def default_record_class
        self.class.record_classes[self.class.use_record_class]
      end

      def fetch_and_hydrate(record_klass, primary_key)
        errors = Quiver::ErrorCollection.new

        if record = record_klass.find_by(primary_key_name => primary_key)
          attributes = load_additional([record.attributes]).first

          object = hydrate(attributes)
        else
          errors << Quiver::Mapper::NotFoundError.new('record', 'not_found')
          object = nil
        end

        Quiver::Mapper::MapperResult.new(object, errors)
      end

      def base_query
        default_record_class.where({})
      end

      def base_count_query
        default_record_class.where({})
      end

      def filter_klass
        Quiver::Adapter::ActiveRecordAdapterFilter
      end

      def load_additional(items)
        items
      end

      def mappings(attributes, p)
        p.map(
          attributes,
          to: self.class.use_record_class,
          primary: true
        )
      end

      def create_mappings(attributes, p)
        mappings(attributes, p)
      end

      def update_mappings(attributes, p)
        mappings(attributes, p)
      end

      def delete_mappings(attributes, p)
        mappings(attributes, p)
      end
    end

    ActiveRecordHelpers = ActiveRecord
  end
end
