module Quiver
  module Adapter
    class AdapterResult
      include Quiver::Result
    end

    def self.included(host)
      host.send(:extend, ClassMethods)
    end

    module ClassMethods
      def adapter_type(val=nil)
        if val
          @adapter_type = val
        end

        @adapter_type
      end

      def primary_key_name(val=nil)
        if val
          @primary_key_name = val
        end

        if @primary_key_name.nil?
          raise RuntimeError, 'mapper adapters must specify primary_key_name'
        end

        @primary_key_name
      end
    end

    def adapter_type
      self.class.adapter_type
    end

    private

    attr_accessor :mapper_klass

    def primary_key_name
      self.class.primary_key_name
    end
  end
end

require 'quiver/adapter/filter_helpers'
require 'quiver/adapter/helpers_helpers'
require 'quiver/adapter/memory_helpers'
require 'quiver/adapter/memory_uuid_primary_key'
require 'quiver/adapter/active_record_helpers'
