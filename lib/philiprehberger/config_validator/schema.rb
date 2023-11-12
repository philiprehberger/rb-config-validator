# frozen_string_literal: true

module Philiprehberger
  module ConfigValidator
    # DSL for defining configuration schemas
    class Schema
      # @return [Array<Rule>] the defined rules
      attr_reader :rules

      # @return [Array<Hash>] nested schema definitions
      attr_reader :nested_schemas

      # @return [Array<Hash>] custom predicate validations
      attr_reader :custom_validators

      # @return [Array<Hash>] pattern validations
      attr_reader :pattern_validators

      # @return [Array<Hash>] range validations
      attr_reader :range_validators

      def initialize
        @rules = []
        @nested_schemas = []
        @custom_validators = []
        @pattern_validators = []
        @range_validators = []
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

      # Define a nested schema for a hash key
      #
      # @param key [Symbol] the configuration key
      # @param required [Boolean] whether the key is required
      # @yield [Schema] the nested schema instance for DSL evaluation
      # @return [void]
      def nested(key, required: true, &block)
        child = Schema.new
        child.instance_eval(&block)
        @nested_schemas << { key: key, schema: child, required: required }
      end

      # Define a custom predicate validation
      #
      # @param key [Symbol] the configuration key
      # @param message [String] error message when validation fails
      # @yield [Object] the value to validate
      # @yieldreturn [Boolean] true if valid, false if invalid
      # @return [void]
      def validate_with(key, message: 'is invalid', &block)
        @custom_validators << { key: key, message: message, block: block }
      end

      # Define a regex pattern validation for string values
      #
      # @param key [Symbol] the configuration key
      # @param regex [Regexp] the pattern to match
      # @param message [String, nil] custom error message
      # @return [void]
      def pattern(key, regex, message: nil)
        @pattern_validators << { key: key, regex: regex, message: message || 'does not match expected pattern' }
      end

      # Define a numeric range validation
      #
      # @param key [Symbol] the configuration key
      # @param min [Numeric, nil] minimum value (inclusive)
      # @param max [Numeric, nil] maximum value (inclusive)
      # @return [void]
      def range(key, min: nil, max: nil)
        @range_validators << { key: key, min: min, max: max }
      end

      # Validate a configuration hash against all rules
      #
      # @param config [Hash] the configuration to validate
      # @return [Array<String>] validation error messages
      def validate(config)
        apply_defaults(config)
        errors = rules.flat_map { |rule| rule.validate(config) }
        errors.concat(validate_nested(config))
        errors.concat(validate_custom(config))
        errors.concat(validate_patterns(config))
        errors.concat(validate_ranges(config))
        errors
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

      def resolve_value(config, key)
        if config.key?(key)
          config[key]
        elsif config.key?(key.to_s)
          config[key.to_s]
        end
      end

      def key_present?(config, key)
        config.key?(key) || config.key?(key.to_s)
      end

      def validate_nested(config)
        nested_schemas.flat_map do |entry|
          key = entry[:key]
          schema = entry[:schema]
          is_required = entry[:required]
          value = resolve_value(config, key)

          if value.nil?
            if is_required
              ["missing required key '#{key}'"]
            else
              []
            end
          elsif !value.is_a?(Hash)
            ["key '#{key}' expected Hash, got #{value.class}"]
          else
            schema.validate(value).map { |msg| "#{key}.#{msg}" }
          end
        end
      end

      def validate_custom(config)
        custom_validators.each_with_object([]) do |entry, errors|
          key = entry[:key]
          next unless key_present?(config, key)

          value = resolve_value(config, key)
          errors << "key '#{key}' #{entry[:message]}" unless entry[:block].call(value)
        end
      end

      def validate_patterns(config)
        pattern_validators.each_with_object([]) do |entry, errors|
          key = entry[:key]
          next unless key_present?(config, key)

          value = resolve_value(config, key)
          next unless value.is_a?(String)

          errors << "key '#{key}' #{entry[:message]}" unless value.match?(entry[:regex])
        end
      end

      def validate_ranges(config)
        range_validators.each_with_object([]) do |entry, errors|
          key = entry[:key]
          next unless key_present?(config, key)

          value = resolve_value(config, key)
          next unless value.is_a?(Numeric)

          if entry[:min] && value < entry[:min]
            errors << "key '#{key}' must be >= #{entry[:min]}, got #{value}"
          end
          next unless entry[:max] && value > entry[:max]

          errors << "key '#{key}' must be <= #{entry[:max]}, got #{value}"
        end
      end
    end
  end
end
