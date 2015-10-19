module Quiver
  module Adapter
    module HelpersHelpers
      def self.included(host)
        host.send(:extend, SelfMethods)
      end

      module SelfMethods
        def included(host)
          if !host.is_a?(Quiver::Adapter)
            host.send(:include, Quiver::Adapter)
          end
        end
      end

      private

      def mapper_name
        @mapper_name ||= self.class.parent.name.split('::').last.underscore
      end

      def when_valid(model, adapter_op)
        raise ArgumentError, "requires block" unless block_given?

        errors = model.validate(
          tags: [adapter_op],
          mapper: mapper_klass.new,
          model: model,
          adapter: self
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

      def hydrate(attributes)
        mapper_klass.hydrate(attributes).tap do |obj|
          obj.persisted_by!(adapter_type)
        end
      end
    end
  end
end
