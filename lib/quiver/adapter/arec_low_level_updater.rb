module Quiver
  module Adapter
    module ActiveRecord
      class ARecLowLevelUpdater
        def initialize(adapter_klass, original_attributes)
          self.adapter_klass = adapter_klass
          self.failed = false
          self.original_attributes = original_attributes
          self.attrs = {}
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

          result = record.update_all(attributes)

          if result == 0
            self.failed = true
          end
        end

        def map_array(h, opts)
          raise ArgumentError, 'map_array requires opts[foreign_key] to be set' unless opts[:foreign_key]

          h.each do |key, items|
            record = record_class(opts[:to])
            query = record.where(opts[:foreign_key])

            ids = record.pluck(:id)
            remaining_ids = items.map { |i| i[:id] }.compact
            remove_ids = ids - remaining_ids

            query.where(id: remove_ids).delete_all

            attrs[key] = items.map do |item|
              item = item.merge(opts[:foreign_key])

              if item[:id]
                result = query.where(id: item[:id]).update_all(item)

                if result != 1
                  self.failed = true
                else
                  item
                end
              else
                result = record.create(item)

                if !result.persisted?
                  self.failed = true
                else
                  result.attributes.symbolize_keys
                end
              end
            end
          end
        end

        def success?
          !failed
        end

        def failed!
          self.failed = true
        end

        def result
          r = original_attributes.symbolize_keys.merge(attrs.merge(
            adapter_klass.primary_key_name => primary_key
          ).symbolize_keys)

          if original_attributes[:__type__]
            r.merge!(
              original_attributes[:__type__][:name] => original_attributes[:__type__][:value]
            )
          end

          r
        end

        def primary_key
          original_attributes[adapter_klass.primary_key_name]
        end

        private

        attr_accessor :adapter_klass, :failed, :mapper_klass, :original_attributes, :attrs

        def record_class(name)
          adapter_klass.record_classes[name]
        end
      end
    end
  end
end
