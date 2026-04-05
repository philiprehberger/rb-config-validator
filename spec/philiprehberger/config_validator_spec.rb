# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::ConfigValidator do
  it 'has a version number' do
    expect(Philiprehberger::ConfigValidator::VERSION).not_to be_nil
  end

  describe '.define' do
    it 'raises an error without a block' do
      expect { described_class.define }.to raise_error(Philiprehberger::ConfigValidator::Error, 'a block is required')
    end

    it 'returns a Schema' do
      schema = described_class.define do
        required :name, String
      end
      expect(schema).to be_a(Philiprehberger::ConfigValidator::Schema)
    end

    it 'returns a schema with rules' do
      schema = described_class.define do
        required :a, String
        optional :b, Integer
      end
      expect(schema.rules.length).to eq(2)
    end
  end

  describe 'required keys' do
    it 'passes when required key is present with correct type' do
      schema = described_class.define do
        required :db_url, String
      end
      expect(schema.validate({ db_url: 'postgres://localhost/db' })).to be_empty
    end

    it 'reports missing required keys' do
      schema = described_class.define do
        required :db_url, String
      end
      errors = schema.validate({})
      expect(errors).to include(match(/missing required key 'db_url'/))
    end

    it 'reports type mismatch for required keys' do
      schema = described_class.define do
        required :port, Integer
      end
      errors = schema.validate({ port: 'not a number' })
      expect(errors).to include(match(/key 'port' expected Integer/))
    end

    it 'reports multiple missing required keys' do
      schema = described_class.define do
        required :host, String
        required :port, Integer
        required :db, String
      end
      errors = schema.validate({})
      expect(errors.length).to eq(3)
    end

    it 'passes with nil value when key is not required' do
      schema = described_class.define do
        optional :debug, TrueClass
      end
      expect(schema.validate({})).to be_empty
    end

    it 'reports error when required key has nil value' do
      schema = described_class.define do
        required :name, String
      end
      errors = schema.validate({ name: nil })
      expect(errors).to include(match(/missing required key 'name'/))
    end
  end

  describe 'optional keys' do
    it 'passes when optional key is absent' do
      schema = described_class.define do
        optional :port, Integer, default: 3000
      end
      expect(schema.validate({})).to be_empty
    end

    it 'applies default value when optional key is missing' do
      schema = described_class.define do
        optional :port, Integer, default: 3000
      end
      config = {}
      schema.validate(config)
      expect(config[:port]).to eq(3000)
    end

    it 'does not override existing value with default' do
      schema = described_class.define do
        optional :port, Integer, default: 3000
      end
      config = { port: 8080 }
      schema.validate(config)
      expect(config[:port]).to eq(8080)
    end

    it 'validates type of optional key when present' do
      schema = described_class.define do
        optional :port, Integer
      end
      errors = schema.validate({ port: 'not a number' })
      expect(errors).to include(match(/key 'port' expected Integer/))
    end

    it 'does not apply default when value is nil and no default set' do
      schema = described_class.define do
        optional :color, String
      end
      config = {}
      schema.validate(config)
      expect(config).not_to have_key(:color)
    end

    it 'applies a string default value' do
      schema = described_class.define do
        optional :env, String, default: 'development'
      end
      config = {}
      schema.validate(config)
      expect(config[:env]).to eq('development')
    end

    it 'applies a boolean default value' do
      schema = described_class.define do
        optional :debug, TrueClass, default: false
      end
      config = {}
      schema.validate(config)
      expect(config[:debug]).to eq(false)
    end

    it 'does not apply default when string key exists' do
      schema = described_class.define do
        optional :port, Integer, default: 3000
      end
      config = { 'port' => 9090 }
      schema.validate(config)
      expect(config['port']).to eq(9090)
      expect(config).not_to have_key(:port)
    end
  end

  describe 'one_of constraint' do
    it 'passes when value is in allowed list' do
      schema = described_class.define do
        required :env, String, one_of: %w[dev staging prod]
      end
      expect(schema.validate({ env: 'prod' })).to be_empty
    end

    it 'reports error when value is not in allowed list' do
      schema = described_class.define do
        required :env, String, one_of: %w[dev staging prod]
      end
      errors = schema.validate({ env: 'test' })
      expect(errors).to include(match(/key 'env' must be one of/))
    end

    it 'works with integer allowed values' do
      schema = described_class.define do
        required :level, Integer, one_of: [1, 2, 3]
      end
      expect(schema.validate({ level: 2 })).to be_empty
    end

    it 'reports error for integer not in allowed list' do
      schema = described_class.define do
        required :level, Integer, one_of: [1, 2, 3]
      end
      errors = schema.validate({ level: 5 })
      expect(errors).to include(match(/must be one of/))
    end

    it 'works with optional keys and one_of' do
      schema = described_class.define do
        optional :color, String, one_of: %w[red green blue]
      end
      errors = schema.validate({ color: 'yellow' })
      expect(errors).to include(match(/must be one of/))
    end

    it 'passes when optional key with one_of is absent' do
      schema = described_class.define do
        optional :color, String, one_of: %w[red green blue]
      end
      expect(schema.validate({})).to be_empty
    end
  end

  describe 'string keys' do
    it 'accepts string keys in the config hash' do
      schema = described_class.define do
        required :name, String
      end
      expect(schema.validate({ 'name' => 'Alice' })).to be_empty
    end

    it 'validates type for string keys' do
      schema = described_class.define do
        required :port, Integer
      end
      errors = schema.validate({ 'port' => 'abc' })
      expect(errors).to include(match(/expected Integer/))
    end
  end

  describe 'type validation' do
    it 'validates String type' do
      schema = described_class.define { required :v, String }
      expect(schema.validate({ v: 'hello' })).to be_empty
    end

    it 'validates Integer type' do
      schema = described_class.define { required :v, Integer }
      expect(schema.validate({ v: 42 })).to be_empty
    end

    it 'validates Float type' do
      schema = described_class.define { required :v, Float }
      expect(schema.validate({ v: 3.14 })).to be_empty
    end

    it 'validates Array type' do
      schema = described_class.define { required :v, Array }
      expect(schema.validate({ v: [1, 2] })).to be_empty
    end

    it 'validates Hash type' do
      schema = described_class.define { required :v, Hash }
      expect(schema.validate({ v: { a: 1 } })).to be_empty
    end

    it 'reports error for wrong type with descriptive message' do
      schema = described_class.define { required :v, Integer }
      errors = schema.validate({ v: 'hello' })
      expect(errors.first).to include('expected Integer')
      expect(errors.first).to include('got String')
    end
  end

  describe '.validate' do
    it 'validates with an inline block' do
      errors = described_class.validate({ db_url: 'postgres://localhost' }) do
        required :db_url, String
        required :port, Integer
      end
      expect(errors).to include(match(/missing required key 'port'/))
    end

    it 'returns empty array for valid config' do
      errors = described_class.validate({ name: 'test' }) do
        required :name, String
      end
      expect(errors).to be_empty
    end
  end

  describe '.validate!' do
    it 'returns config when valid' do
      config = { db_url: 'postgres://localhost', port: 5432 }
      result = described_class.validate!(config) do
        required :db_url, String
        required :port, Integer
      end
      expect(result).to eq(config)
    end

    it 'raises ValidationError when invalid' do
      expect do
        described_class.validate!({}) do
          required :db_url, String
        end
      end.to raise_error(Philiprehberger::ConfigValidator::ValidationError, /missing required key/)
    end

    it 'includes all errors in the exception message' do
      expect do
        described_class.validate!({}) do
          required :a, String
          required :b, Integer
        end
      end.to raise_error(Philiprehberger::ConfigValidator::ValidationError, /a.*b/m)
    end

    it 'applies defaults before returning' do
      config = { name: 'test' }
      described_class.validate!(config) do
        required :name, String
        optional :port, Integer, default: 3000
      end
      expect(config[:port]).to eq(3000)
    end
  end

  describe 'complex schema' do
    it 'validates a full configuration' do
      schema = described_class.define do
        required :db_url, String
        optional :port, Integer, default: 3000
        required :env, String, one_of: %w[dev staging prod]
        optional :debug, TrueClass
      end

      config = { db_url: 'postgres://localhost/mydb', env: 'prod' }
      errors = schema.validate(config)
      expect(errors).to be_empty
      expect(config[:port]).to eq(3000)
    end

    it 'collects errors from multiple rules' do
      schema = described_class.define do
        required :db_url, String
        required :port, Integer
        required :env, String, one_of: %w[dev staging prod]
      end

      errors = schema.validate({ port: 'wrong', env: 'invalid' })
      expect(errors.length).to eq(3)
    end

    it 'handles mixed symbol and string keys together' do
      schema = described_class.define do
        required :host, String
        required :port, Integer
      end

      config = { host: 'localhost', 'port' => 5432 }
      expect(schema.validate(config)).to be_empty
    end
  end

  describe 'nested schema validation' do
    it 'validates a valid nested hash' do
      schema = described_class.define do
        nested :database do
          required :host, String
          required :port, Integer
        end
      end
      config = { database: { host: 'localhost', port: 5432 } }
      expect(schema.validate(config)).to be_empty
    end

    it 'reports missing required nested key' do
      schema = described_class.define do
        nested :database do
          required :host, String
        end
      end
      errors = schema.validate({})
      expect(errors).to include(match(/missing required key 'database'/))
    end

    it 'reports invalid values inside nested hash' do
      schema = described_class.define do
        nested :database do
          required :port, Integer
        end
      end
      errors = schema.validate({ database: { port: 'abc' } })
      expect(errors).to include(match(/database\.key 'port' expected Integer/))
    end

    it 'reports error when nested value is not a Hash' do
      schema = described_class.define do
        nested :database do
          required :host, String
        end
      end
      errors = schema.validate({ database: 'not a hash' })
      expect(errors).to include(match(/key 'database' expected Hash, got String/))
    end

    it 'reports error when nested value is nil' do
      schema = described_class.define do
        nested :database do
          required :host, String
        end
      end
      errors = schema.validate({ database: nil })
      expect(errors).to include(match(/missing required key 'database'/))
    end

    it 'allows optional nested key to be absent' do
      schema = described_class.define do
        nested :cache, required: false do
          required :ttl, Integer
        end
      end
      expect(schema.validate({})).to be_empty
    end

    it 'validates deeply nested schemas' do
      schema = described_class.define do
        nested :database do
          required :host, String
          nested :pool do
            required :size, Integer
            nested :timeout do
              required :connect, Integer
              required :read, Integer
            end
          end
        end
      end

      config = {
        database: {
          host: 'localhost',
          pool: {
            size: 5,
            timeout: { connect: 5, read: 30 }
          }
        }
      }
      expect(schema.validate(config)).to be_empty
    end

    it 'reports errors in deeply nested schemas with path prefix' do
      schema = described_class.define do
        nested :database do
          nested :pool do
            required :size, Integer
          end
        end
      end

      errors = schema.validate({ database: { pool: { size: 'big' } } })
      expect(errors).to include(match(/database\.pool\.key 'size' expected Integer/))
    end

    it 'combines nested with other validators' do
      schema = described_class.define do
        required :name, String
        nested :database do
          required :host, String
        end
        optional :port, Integer, default: 3000
      end

      config = { name: 'app', database: { host: 'localhost' } }
      errors = schema.validate(config)
      expect(errors).to be_empty
      expect(config[:port]).to eq(3000)
    end
  end

  describe 'custom predicate validation (validate_with)' do
    it 'passes when predicate returns true' do
      schema = described_class.define do
        required :email, String
        validate_with(:email) { |v| v.include?('@') }
      end
      expect(schema.validate({ email: 'user@example.com' })).to be_empty
    end

    it 'reports error when predicate returns false' do
      schema = described_class.define do
        required :email, String
        validate_with(:email) { |v| v.include?('@') }
      end
      errors = schema.validate({ email: 'not-an-email' })
      expect(errors).to include(match(/key 'email' is invalid/))
    end

    it 'uses custom error message' do
      schema = described_class.define do
        required :age, Integer
        validate_with(:age, message: 'must be positive', &:positive?)
      end
      errors = schema.validate({ age: -1 })
      expect(errors).to include(match(/key 'age' must be positive/))
    end

    it 'skips validation when key is absent' do
      schema = described_class.define do
        optional :score, Integer
        validate_with(:score) { |v| v > 0 }
      end
      expect(schema.validate({})).to be_empty
    end
  end

  describe 'pattern validation' do
    it 'passes when value matches regex' do
      schema = described_class.define do
        required :email, String
        pattern :email, /\A[^@]+@[^@]+\z/
      end
      expect(schema.validate({ email: 'user@example.com' })).to be_empty
    end

    it 'reports error when value does not match regex' do
      schema = described_class.define do
        required :email, String
        pattern :email, /\A[^@]+@[^@]+\z/
      end
      errors = schema.validate({ email: 'invalid' })
      expect(errors).to include(match(/key 'email' does not match expected pattern/))
    end

    it 'uses custom error message' do
      schema = described_class.define do
        required :code, String
        pattern :code, /\A[A-Z]{3}\z/, message: 'must be 3 uppercase letters'
      end
      errors = schema.validate({ code: 'abc' })
      expect(errors).to include(match(/key 'code' must be 3 uppercase letters/))
    end

    it 'skips pattern check for non-string values' do
      schema = described_class.define do
        required :count, Integer
        pattern :count, /\d+/
      end
      expect(schema.validate({ count: 42 })).to be_empty
    end

    it 'skips pattern check when key is absent' do
      schema = described_class.define do
        optional :tag, String
        pattern :tag, /\A[a-z]+\z/
      end
      expect(schema.validate({})).to be_empty
    end
  end

  describe 'Schema#to_example' do
    it 'uses default values when available' do
      schema = described_class.define do
        optional :port, Integer, default: 3000
        optional :host, String, default: 'localhost'
      end
      example = schema.to_example
      expect(example[:port]).to eq(3000)
      expect(example[:host]).to eq('localhost')
    end

    it 'uses first allowed value when one_of is set and no default' do
      schema = described_class.define do
        required :env, String, one_of: %w[dev staging prod]
      end
      example = schema.to_example
      expect(example[:env]).to eq('dev')
    end

    it 'uses placeholder for String type' do
      schema = described_class.define do
        required :name, String
      end
      expect(schema.to_example[:name]).to eq('example')
    end

    it 'uses placeholder for Integer type' do
      schema = described_class.define do
        required :count, Integer
      end
      expect(schema.to_example[:count]).to eq(0)
    end

    it 'uses placeholder for Float type' do
      schema = described_class.define do
        required :rate, Float
      end
      expect(schema.to_example[:rate]).to eq(0.0)
    end

    it 'uses placeholder for TrueClass type' do
      schema = described_class.define do
        required :flag, TrueClass
      end
      expect(schema.to_example[:flag]).to eq(false)
    end

    it 'uses placeholder for Array type' do
      schema = described_class.define do
        required :items, Array
      end
      expect(schema.to_example[:items]).to eq([])
    end

    it 'uses placeholder for Hash type' do
      schema = described_class.define do
        required :meta, Hash
      end
      expect(schema.to_example[:meta]).to eq({})
    end

    it 'returns nil for unknown types' do
      schema = described_class.define do
        required :custom, Regexp
      end
      expect(schema.to_example[:custom]).to be_nil
    end

    it 'prefers default over allowed_values' do
      schema = described_class.define do
        optional :env, String, default: 'staging', one_of: %w[dev staging prod]
      end
      expect(schema.to_example[:env]).to eq('staging')
    end

    it 'generates a complete example from a mixed schema' do
      schema = described_class.define do
        required :db_url, String
        optional :port, Integer, default: 3000
        required :env, String, one_of: %w[dev staging prod]
        optional :debug, TrueClass
      end
      example = schema.to_example
      expect(example).to eq({
                              db_url: 'example',
                              port: 3000,
                              env: 'dev',
                              debug: false
                            })
    end
  end

  describe 'range validation' do
    it 'passes when value is within range (both bounds)' do
      schema = described_class.define do
        required :port, Integer
        range :port, min: 1, max: 65_535
      end
      expect(schema.validate({ port: 8080 })).to be_empty
    end

    it 'reports error when value is below minimum' do
      schema = described_class.define do
        required :port, Integer
        range :port, min: 1, max: 65_535
      end
      errors = schema.validate({ port: 0 })
      expect(errors).to include(match(/key 'port' must be >= 1/))
    end

    it 'reports error when value is above maximum' do
      schema = described_class.define do
        required :port, Integer
        range :port, min: 1, max: 65_535
      end
      errors = schema.validate({ port: 70_000 })
      expect(errors).to include(match(/key 'port' must be <= 65535/))
    end

    it 'validates with min only' do
      schema = described_class.define do
        required :count, Integer
        range :count, min: 0
      end
      expect(schema.validate({ count: 0 })).to be_empty
      errors = schema.validate({ count: -1 })
      expect(errors).to include(match(/must be >= 0/))
    end

    it 'validates with max only' do
      schema = described_class.define do
        required :score, Integer
        range :score, max: 100
      end
      expect(schema.validate({ score: 100 })).to be_empty
      errors = schema.validate({ score: 101 })
      expect(errors).to include(match(/must be <= 100/))
    end

    it 'skips range check for non-numeric values' do
      schema = described_class.define do
        required :name, String
        range :name, min: 1, max: 10
      end
      expect(schema.validate({ name: 'hello' })).to be_empty
    end

    it 'skips range check when key is absent' do
      schema = described_class.define do
        optional :priority, Integer
        range :priority, min: 1, max: 5
      end
      expect(schema.validate({})).to be_empty
    end

    it 'works with float values' do
      schema = described_class.define do
        required :rate, Float
        range :rate, min: 0.0, max: 1.0
      end
      expect(schema.validate({ rate: 0.5 })).to be_empty
      errors = schema.validate({ rate: 1.5 })
      expect(errors).to include(match(/must be <= 1.0/))
    end
  end

  describe Philiprehberger::ConfigValidator::Rule do
    describe '#key' do
      it 'returns the configured key name' do
        rule = described_class.new(:host, String, required: true)
        expect(rule.key).to eq(:host)
      end
    end

    describe '#type' do
      it 'returns the configured type' do
        rule = described_class.new(:host, String, required: true)
        expect(rule.type).to eq(String)
      end
    end

    describe '#required' do
      it 'returns true for required rules' do
        rule = described_class.new(:host, String, required: true)
        expect(rule.required).to be true
      end

      it 'returns false for optional rules' do
        rule = described_class.new(:host, String, required: false)
        expect(rule.required).to be false
      end
    end

    describe '#default' do
      it 'returns the default value' do
        rule = described_class.new(:port, Integer, required: false, default: 3000)
        expect(rule.default).to eq(3000)
      end

      it 'returns nil when no default set' do
        rule = described_class.new(:port, Integer, required: false)
        expect(rule.default).to be_nil
      end
    end

    describe '#allowed_values' do
      it 'returns the one_of values' do
        rule = described_class.new(:env, String, required: true, one_of: %w[a b])
        expect(rule.allowed_values).to eq(%w[a b])
      end
    end
  end
end
