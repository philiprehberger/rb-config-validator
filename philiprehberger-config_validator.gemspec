# frozen_string_literal: true

require_relative 'lib/philiprehberger/config_validator/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-config_validator'
  spec.version       = Philiprehberger::ConfigValidator::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']

  spec.summary       = 'Configuration schema validator with type checking and helpful error messages'
  spec.description   = 'Define configuration schemas with required and optional keys, type constraints, ' \
                       'default values, and allowed value lists. Validates hashes and raises descriptive errors.'
  spec.homepage      = 'https://github.com/philiprehberger/rb-config-validator'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['changelog_uri']         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']       = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
