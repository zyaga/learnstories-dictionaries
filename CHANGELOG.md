# Changelog

All notable changes to the LearnStories dictionaries will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-02-10

### Added
- Initial versioned release with GitHub Releases
- Japanese dictionary (JMdict 77MB, 180K entries)
- Chinese dictionary (CC-CEDICT 27MB, 120K entries)
- Korean dictionary (KRDICT 8.6MB, 45K entries)
- Spanish dictionary (Wiktionary 96MB, 256K entries)
- Italian dictionary (Kaikki.org 74MB, 198K entries)
- Russian dictionary (OpenRussian 9.8MB, 87K entries)
- Release automation script with MD5 checksums
- Version tracking system with checksums for differential updates

### Changed
- Migrated from raw Git LFS URLs to GitHub Release assets for better performance
- Renamed dictionary files to match language codes (e.g., jmdict.db → ja.db)
