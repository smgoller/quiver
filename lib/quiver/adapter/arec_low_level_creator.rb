module Quiver
  module Adapter
    module ActiveRecord
      class ARecLowLevelCreator
        attr_reader :primary_key

        def initialize(adapter_klass, original_attributes)
          self.adapter_klass = adapter_klass
          self.failed = false
          self.original_attributes = original_attributes
          self.attrs = {}
        end

        def map(attributes, opts)
          if opts[:foreign_key]
            attributes.merge!(opts[:foreign_key])
          end

          if opts[:primary] && original_attributes[:__type__]
            attributes.merge!(
              original_attributes[:__type__][:name] => original_attributes[:__type__][:value]
            )
          end

          record = record_class(opts[:to]).create(attributes)

          if record.persisted?
            attrs.merge!(record.attributes)

            if opts[:primary]
              self.primary_key = record.send(adapter_klass.primary_key_name)
            end
          else
            self.failed = true
          end
        end

        def map_array(h, opts)
          h.each do |key, items|
            attrs[key] = items.map do |attributes|
              if opts[:foreign_key]
                attributes.merge!(opts[:foreign_key])
              end

              record = record_class(opts[:to]).create(attributes)

              if record.persisted?
                attributes.merge(id: record.id)
              else
                self.failed = true
                {}
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
          original_attributes.symbolize_keys.merge(attrs.merge(
            adapter_klass.primary_key_name => primary_key
          ).symbolize_keys)
        end

        private

        attr_accessor :adapter_klass, :failed, :original_attributes, :attrs, :mapper_klass
        attr_writer :primary_key

        def record_class(name)
          adapter_klass.record_classes[name]
        end
      end
    end
  end
end
