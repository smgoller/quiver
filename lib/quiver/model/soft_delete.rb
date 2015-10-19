module Quiver
  module Model
    module SoftDelete

      def self.included(host)
        host.send(:attribute, :deleted_at, Time)
      end

      def deleted?
        !!deleted_at
      end
    end
  end
end
