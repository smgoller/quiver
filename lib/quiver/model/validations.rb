module Quiver
  module Model
    module Validations
      def self.included(host)
        host.send(:extend, ClassMethods)
      end

      module ClassMethods
        def validate(attr_or_proc, options={})
          validation_definitions << {
            attr_or_proc: attr_or_proc,
            options: options
          }
        end

        def validator
          @validator ||= Quiver::Validator.new(validation_definitions)
        end

        private

        def validation_definitions
          @validation_definitions ||= []
        end
      end

      def validate(options={})
        result = self.class.validator.validate(self, options)

        if respond_to?(:extant_attributes, true)
          extant_attributes.each do |(key, attr_object)|
            unless coerced?(attr_object.name)
              result << Quiver::Model::ValidationError.new(
                attr_object.name,
                "could_not_be_coerced_to_expected_type.#{attr_object.coercer_name}"
              )
            end
          end
        end

        result
      end
    end
  end
end
