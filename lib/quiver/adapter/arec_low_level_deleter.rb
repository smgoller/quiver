module Quiver
  module Adapter
    module ActiveRecord
      class ARecLowLevelDeleter
        def initialize(adapter_klass, original_attributes)
          self.adapter_klass = adapter_klass
          self.failed = false
          self.original_attributes = original_attributes
          self.attrs = {}
          self.calls = []
        end

        def map(attributes, opts)
          record = record_class(opts[:to])

          if opts[:foreign_key]
            record = record.where(opts[:foreign_key])
          end

          if opts[:primary]
            record = record.where(
              adapter_klass.primary_key_name => primary_key
            )
          end

          calls.unshift -> {
            record.delete_all == 1
          }
        end

        def map_array(h, opts)
          raise ArgumentError, 'map_array requires opts[foreign_key] to be set' unless opts[:foreign_key]

          h.each do |key, items|
            record = record_class(opts[:to])
            query = record.where(opts[:foreign_key])

            remove_ids = record.pluck(:id)

            calls.unshift -> {
              query.where(id: remove_ids).delete_all == remove_ids.count
            }
          end
        end

        def success?
          calls.all? do |call|
            call.call
          end && !failed
        end

        def failed!
          self.failed = true
        end

        def result
          {}
        end

        def primary_key
          original_attributes[adapter_klass.primary_key_name]
        end

        private

        attr_accessor :adapter_klass, :failed, :mapper_klass, :original_attributes, :attrs, :calls

        def record_class(name)
          adapter_klass.record_classes[name]
        end
      end
    end
  end
end
