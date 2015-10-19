module Quiver
  module Mappers
    def self.transaction(&block)
      raise ArgumentError, "#transaction requires a block" unless block_given?

      root_module = self.parent
      adapter_type = root_module::Application.default_adapter_type

      transaction_klass = self.const_get("#{adapter_type.to_s.camelize}Transaction")
      transaction_klass.transaction(root_module, &block)
    end

    class Transaction
      def initialize
        self.rollback = false
      end

      def rollback!
        self.rollback = true
      end

      def rollback?
        rollback
      end

      def good?
        !rollback
      end

      private

      attr_accessor :rollback
    end

    class RollbackTransaction < StandardError; end

    module MemoryTransaction
      def self.transaction(root_module, &block)
        raise ArgumentError, "#transaction requires a block" unless block_given?

        transaction = Transaction.new

        root_module::Application.memory_adapter_store.transaction do
          ret = block.call(transaction)

          raise RollbackTransaction if transaction.rollback?

          ret
        end
      end
    end

    module ActiveRecordTransaction
      def self.transaction(root_module, &block)
        raise ArgumentError, "#transaction requires a block" unless block_given?

        transaction = Transaction.new

        ret = nil

        ActiveRecord::Base.transaction do
          begin
            ret = block.call(transaction)
          rescue ::ActiveRecord::ActiveRecordError, RollbackTransaction
            transaction.rollback!
          end

          raise ActiveRecord::Rollback if transaction.rollback?
        end

        ret
      end
    end
  end
end
