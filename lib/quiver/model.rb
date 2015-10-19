require 'extant'

module Quiver
  module Model
    module ExtantAttributeOverrides
      def with(attrs={}, metadata={})
        super.tap do |new_instance|
          persisted_by.each do |pb|
            new_instance.persisted_by!(pb)
          end
        end
      end

      def dirty?(attr=nil)
        return true unless persisted?

        super
      end
    end

    require 'quiver/model/validations'

    def self.included(host)
      host.send(:include, Extant::Attributes)
      host.send(:include, Validations)
      host.send(:include, ExtantAttributeOverrides)
    end

    def coerced?(attr)
      extant_attributes[attr].set? && extant_attributes[attr].coerced? ||
        extant_attributes[attr].unset? && !extant_attributes[attr].coerced?
    end

    def coerced_all?
      extant_attributes.all? { |(_, attr_object)| attr_object.coerced? }
    end

    def persisted?
      persisted_by.any?
    end

    def persisted_by
      @persisted_by ||= []
    end

    def persisted_by!(adapter_type)
      persisted_by << adapter_type
    end

    def serialization_type
      @serialization_type ||= self.class.name.split('::').last
    end

    def original_attributes
      original_extant_attributes.each_with_object({}) do |(k, v), attrs|
        attrs[k] = v.value
      end
    end
  end
end

require 'quiver/model/validation_error'
require 'quiver/model/soft_delete'
