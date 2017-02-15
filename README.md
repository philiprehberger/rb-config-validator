# philiprehberger-config_validator

[![Tests](https://github.com/philiprehberger/rb-config-validator/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-config-validator/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-config_validator.svg)](https://rubygems.org/gems/philiprehberger-config_validator)
[![License](https://img.shields.io/github/license/philiprehberger/rb-config-validator)](LICENSE)

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
| `Schema#validate(config)` | Validate a config hash, returns array of error strings |
| `Schema#validate!(config)` | Validate a config hash, raises ValidationError on failure |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
