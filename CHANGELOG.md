# Change Log

## [Unreleased]

## [0.3.0] - 2025-12-03

### Fixed
- Added missing `amend:` parameter to `GitDiff.initialize`
- Fixed `check_recent_commit` method signature (was receiving 2 arguments but only accepted 1)
- Fixed `CommitMessageGenerator.initialize` to accept required `model:`, `provider:`, and `amend:` parameters
- Removed dependency on `Aigcm.amend?` from `CommitMessageGenerator#generate` in favor of instance variable
- Added `debug_me` as development dependency
- Added `bundler/setup` to bin/aigcm for proper gem version loading
- Fixed test mocks for `GitDiff` in commit message generator tests

## [0.2.0] - 2025-02-09

- changed gem name to aigcm
- released gem

## [0.1.0] - 2025-02-08

- changed gem name to aigc

## [0.1.0] - 2025-02-07

- Initial release
