# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-04-09

### Added
- `Schema#coerce(config)` for converting string values to expected types (Integer, Float, Boolean)
- `Schema#to_doc` for generating schema documentation as an array of hashes
- `Schema#keys` for listing all defined key names

## [0.3.0] - 2026-04-04

### Added
- `Schema#to_example` method to generate sample config hashes from schema definitions

## [0.2.0] - 2026-04-03

### Added
- Nested schema validation via `nested` for validating nested hashes
- Custom predicate validation via `validate_with`
- Regex pattern validation via `pattern`
- Numeric range validation via `range`

## [0.1.5] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.1.4] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.1.3] - 2026-03-24

### Fixed
- Remove inline comments from Development section to match template

## [0.1.2] - 2026-03-22

### Changed
- Expanded test suite to 30+ examples covering edge cases, error paths, and boundary conditions

## [0.1.1] - 2026-03-22

### Changed
- Version bump for republishing

## [0.1.0] - 2026-03-22

### Added
- Initial release
- Schema DSL with required and optional key definitions
- Type checking for all standard Ruby types
- Default value support for optional keys
- Allowed values constraint via one_of
- Validate method returning error arrays
- Validate! method raising on validation failure
- Descriptive error messages for all constraint violations
