# frozen_string_literal: true

require_relative 'config_validator/version'
require_relative 'config_validator/rule'
require_relative 'config_validator/schema'

module Philiprehberger
  module ConfigValidator
    class Error < StandardError; end

    # Raised when configuration validation fails
    class ValidationError < Error; end

    # Define a configuration schema using a DSL block
    #
    # @yield [Schema] the schema instance for DSL evaluation
    # @return [Schema] the defined schema
    # @raise [Error] if no block is given
    def self.define(&block)
      raise Error, 'a block is required' unless block

      schema = Schema.new
      schema.instance_eval(&block)
      schema
    end

    # Validate a configuration hash against a schema defined in a block
    #
    # @param config [Hash] the configuration to validate
    # @yield [Schema] the schema definition block
    # @return [Array<String>] validation error messages
    def self.validate(config, &)
      schema = define(&)
      schema.validate(config)
    end

    # Validate a configuration hash and raise on errors
    #
    # @param config [Hash] the configuration to validate
    # @yield [Schema] the schema definition block
    # @return [Hash] the validated configuration with defaults applied
    # @raise [ValidationError] if validation fails
    def self.validate!(config, &)
      schema = define(&)
      schema.validate!(config)
    end
  end
end
