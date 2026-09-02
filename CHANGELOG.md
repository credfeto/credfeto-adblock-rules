# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
Please ADD ALL Changes to the UNRELASED SECTION and not a specific release
-->

## [Unreleased]
### Security
### Added
- Local nginx server setup (server/install.sh): serves adblock.txt and hosts.txt over internal HTTP from an hourly-synced clone, so LAN consumers need no external egress
### Fixed
### Changed
- Pin GitHub Actions `uses:` references to commit SHA instead of tag
- Hardened the GitHub Pages deploy workflow: single-commit gh-pages publishes (force_orphan) and shallow checkout
### Deprecated
### Removed
### Deployment Changes

<!--
Releases that have at least been deployed to staging, BUT NOT necessarily released to live.  Changes should be moved from [Unreleased] into here as they are merged into the appropriate release branch
-->

## [0.0.0] - Project created