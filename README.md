# philiprehberger-config_validator

[![Tests](https://github.com/philiprehberger/rb-config-validator/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-config-validator/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-config_validator.svg)](https://rubygems.org/gems/philiprehberger-config_validator)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-config-validator)](https://github.com/philiprehberger/rb-config-validator/commits/main)

Configuration schema validator with type checking and helpful error messages

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-config_validator"
```

Or install directly:

```bash
gem install philiprehberger-config_validator
```

## Usage

```ruby
require "philiprehberger/config_validator"

schema = Philiprehberger::ConfigValidator.define do
  required :db_url, String
  optional :port, Integer, default: 3000
  required :env, String, one_of: %w[dev staging prod]
end

errors = schema.validate({ db_url: 'postgres://localhost/mydb', env: 'prod' })
# => []
```

### Required Keys

```ruby
schema = Philiprehberger::ConfigValidator.define do
  required :db_url, String
  required :secret_key, String
end

errors = schema.validate({})
# => ["missing required key 'db_url'", "missing required key 'secret_key'"]
```

### Optional Keys with Defaults

```ruby
schema = Philiprehberger::ConfigValidator.define do
  optional :port, Integer, default: 3000
  optional :host, String, default: 'localhost'
end

config = {}
schema.validate(config)
config[:port]  # => 3000
config[:host]  # => "localhost"
```

### Allowed Values

```ruby
schema = Philiprehberger::ConfigValidator.define do
  required :env, String, one_of: %w[dev staging prod]
end

schema.validate({ env: 'test' })
# => ["key 'env' must be one of [\"dev\", \"staging\", \"prod\"], got \"test\""]
```

### Validate with Raise

```ruby
schema.validate!({ env: 'invalid' })
# => raises Philiprehberger::ConfigValidator::ValidationError
```

### Nested Schemas

```ruby
schema = Philiprehberger::ConfigValidator.define do
  nested :database do
    required :host, String
    required :port, Integer
    nested :pool do
      required :size, Integer
    end
  end
end

errors = schema.validate({ database: { host: 'localhost', port: 5432, pool: { size: 5 } } })
# => []
```

### Custom Validators

```ruby
schema = Philiprehberger::ConfigValidator.define do
  required :email, String
  validate_with(:email, message: 'must contain @') { |v| v.include?('@') }
end

schema.validate({ email: 'invalid' })
# => ["key 'email' must contain @"]
```

### Pattern Matching

```ruby
schema = Philiprehberger::ConfigValidator.define do
  required :code, String
  pattern :code, /\A[A-Z]{3}-\d{4}\z/, message: 'must match format XXX-0000'
end

schema.validate({ code: 'abc' })
# => ["key 'code' must match format XXX-0000"]
```

### Range Validation

```ruby
schema = Philiprehberger::ConfigValidator.define do
  required :port, Integer
  range :port, min: 1, max: 65535
end

schema.validate({ port: 70000 })
# => ["key 'port' must be <= 65535, got 70000"]
```

### Example Generation

```ruby
schema = Philiprehberger::ConfigValidator.define do
  required :db_url, String
  optional :port, Integer, default: 3000
  required :env, String, one_of: %w[dev staging prod]
  optional :debug, TrueClass
end

schema.to_example
# => { db_url: "example", port: 3000, env: "dev", debug: false }
```

### Type Coercion from Strings

Useful when config comes from ENV where all values are strings:

```ruby
schema = Philiprehberger::ConfigValidator.define do
  required :port, Integer
  required :debug, TrueClass
end

config = { port: '8080', debug: 'true' }
schema.coerce(config)
config[:port]   # => 8080 (Integer)
config[:debug]  # => true (Boolean)

schema.validate(config) # => []
```

### Schema Documentation

```ruby
schema = Philiprehberger::ConfigValidator.define do
  required :db_url, String
  optional :port, Integer, default: 3000
  required :env, String, one_of: %w[dev staging prod]
end

schema.to_doc
# => [
#   { key: :db_url, type: "String", required: true, default: nil, constraints: nil },
#   { key: :port,   type: "Integer", required: false, default: 3000, constraints: nil },
#   { key: :env,    type: "String", required: true, default: nil, constraints: "one of: [\"dev\", ...]" }
# ]

schema.keys  # => [:db_url, :port, :env]
```

### Inline Validation

```ruby
errors = Philiprehberger::ConfigValidator.validate(config) do
  required :db_url, String
  optional :port, Integer, default: 3000
end
```

## API

| Method | Description |
|--------|-------------|
| `ConfigValidator.define { ... }` | Define a configuration schema, returns a Schema |
| `ConfigValidator.validate(config) { ... }` | Define and validate in one step, returns error array |
| `ConfigValidator.validate!(config) { ... }` | Define and validate, raises on errors |
| `Schema#required(key, type, one_of:)` | Define a required key with type and optional constraint |
| `Schema#optional(key, type, default:, one_of:)` | Define an optional key with default and constraint |
| `Schema#nested(key, required:, &block)` | Define a nested schema for a hash key |
| `Schema#validate_with(key, message:, &block)` | Custom predicate validation |
| `Schema#pattern(key, regex, message:)` | Regex pattern validation for string values |
| `Schema#range(key, min:, max:)` | Numeric range validation |
| `Schema#to_example` | Generate a sample config hash from the schema definition |
| `Schema#coerce(config)` | Coerce string values to expected types (Integer, Float, Boolean) |
| `Schema#to_doc` | Generate documentation array describing each key |
| `Schema#keys` | Return all defined key names as symbols |
| `Schema#required_keys` | Return array of required key names |
| `Schema#optional_keys` | Return array of optional key names |
| `Schema#validate(config)` | Validate a config hash, returns array of error strings |
| `Schema#validate!(config)` | Validate a config hash, raises ValidationError on failure |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-config-validator)

🐛 [Report issues](https://github.com/philiprehberger/rb-config-validator/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-config-validator/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
