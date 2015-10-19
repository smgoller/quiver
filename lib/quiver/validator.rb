module Quiver
  module Validators; end

  require 'quiver/validators/base'
  require 'quiver/validators/presence'
  require 'quiver/validators/unique'

  class Validator
    VALIDATORS = {
      presence: Quiver::Validators::Presence,
      unique: Quiver::Validators::Unique
    }.freeze

    def initialize(definitions)
      self.definitions = definitions
    end

    def validate(object, options={})
      tags = options[:tags] || []

      error_collections = definitions.map do |definition|
        next unless tags_match?(tags, definition)

        if definition[:options][:if]
          next if !definition[:options][:if].call(object)
        end

        if definition[:options][:unless]
          next if definition[:options][:unless].call(object)
        end

        attr_or_proc = definition[:attr_or_proc]

        validator_options = definition[:options].select do |k, v|
          !%i|except only if unless|.include?(k)
        end

        if attr_or_proc.is_a?(Proc)
          result = attr_or_proc.call(object)

          unless result.is_a?(Quiver::ErrorCollection)
            raise TypeError, 'proc validators must return a Quiver::ErrorCollection'
          end

          result
        else
          value = object.public_send(attr_or_proc)

          results = validator_options.map do |k, v|
            validator_klass = VALIDATORS[k] || next
            validator = validator_klass.new(
              value, v, attr_or_proc, options[:mapper], options[:model]
            )

            validator.validate
          end

          results.compact.reduce(:+)
        end
      end

      error_collections.compact.reduce(:+) || Quiver::ErrorCollection.new
    end

    private

    attr_accessor :definitions

    def tags_match?(tags, definition)
      definition_options = definition[:options]

      if definition_options.key?(:except)
        return false if (definition_options[:except] & tags).any?
      end

      if definition_options.key?(:only)
        return false unless definition_options[:only].any? { |t| tags.include?(t) }
      end

      return true
    end
  end
end
