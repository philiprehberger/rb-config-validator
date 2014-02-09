# frozen_string_literal: true

module Philiprehberger
  module ConfigValidator
    # DSL for defining configuration schemas
    class Schema
      # @return [Array<Rule>] the defined rules
      attr_reader :rules

      def initialize
        @rules = []
      end

      # Define a required configuration key
      #
      # @param key [Symbol] the configuration key
      # @param type [Class] the expected type
      # @param one_of [Array, nil] allowed values constraint
      # @return [void]
      def required(key, type, one_of: nil)
        @rules << Rule.new(key, type, required: true, one_of: one_of)
      end

      # Define an optional configuration key
      #
      # @param key [Symbol] the configuration key
      # @param type [Class] the expected type
      # @param default [Object, nil] the default value
      # @param one_of [Array, nil] allowed values constraint
      # @return [void]
      def optional(key, type, default: nil, one_of: nil)
        @rules << Rule.new(key, type, required: false, default: default, one_of: one_of)
      end

      # Validate a configuration hash against all rules
      #
      # @param config [Hash] the configuration to validate
      # @return [Array<String>] validation error messages
      def validate(config)
        apply_defaults(config)
        rules.flat_map { |rule| rule.validate(config) }
      end

      # Validate a configuration hash and raise on errors
      #
      # @param config [Hash] the configuration to validate
      # @return [Hash] the validated configuration with defaults applied
      # @raise [Philiprehberger::ConfigValidator::ValidationError] if validation fails
      def validate!(config)
        errors = validate(config)
        raise ValidationError, "Configuration invalid: #{errors.join('; ')}" unless errors.empty?

        config
      end

      private

      def apply_defaults(config)
        rules.each { |rule| rule.apply_default(config) }
      end
    end
  end
end
