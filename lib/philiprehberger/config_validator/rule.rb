# frozen_string_literal: true

module Philiprehberger
  module ConfigValidator
    # Represents a single validation rule for a configuration key
    class Rule
      # @return [Symbol] the configuration key
      attr_reader :key

      # @return [Class] the expected type
      attr_reader :type

      # @return [Boolean] whether the key is required
      attr_reader :required

      # @return [Object, nil] the default value
      attr_reader :default

      # @return [Array, nil] allowed values
      attr_reader :allowed_values

      # @param key [Symbol] the configuration key
      # @param type [Class] the expected type
      # @param required [Boolean] whether the key is required
      # @param default [Object, nil] the default value for optional keys
      # @param one_of [Array, nil] allowed values constraint
      def initialize(key, type, required:, default: nil, one_of: nil)
        @key = key
        @type = type
        @required = required
        @default = default
        @allowed_values = one_of
      end

      # Validate a configuration hash against this rule
      #
      # @param config [Hash] the configuration to validate
      # @return [Array<String>] validation error messages
      def validate(config)
        errors = []
        value = resolve_value(config)

        if value.nil?
          errors << "missing required key '#{key}'" if required
          return errors
        end

        validate_type(value, errors)
        validate_allowed(value, errors)

        errors
      end

      # Apply default value to config if key is missing
      #
      # @param config [Hash] the configuration hash
      # @return [void]
      def apply_default(config)
        return if config.key?(key) || config.key?(key.to_s)
        return if default.nil?

        config[key] = default
      end

      private

      def resolve_value(config)
        if config.key?(key)
          config[key]
        elsif config.key?(key.to_s)
          config[key.to_s]
        end
      end

      def validate_type(value, errors)
        return if value.is_a?(type)

        # Allow Integer when Numeric is expected
        return if type == Numeric && value.is_a?(Numeric)

        errors << "key '#{key}' expected #{type}, got #{value.class}"
      end

      def validate_allowed(value, errors)
        return unless allowed_values

        return if allowed_values.include?(value)

        errors << "key '#{key}' must be one of #{allowed_values.inspect}, got #{value.inspect}"
      end
    end
  end
end
