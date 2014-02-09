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
  end

  describe 'string keys' do
    it 'accepts string keys in the config hash' do
      schema = described_class.define do
        required :name, String
      end
      expect(schema.validate({ 'name' => 'Alice' })).to be_empty
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
  end
end
