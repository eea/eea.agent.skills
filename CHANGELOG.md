# Changelog

All notable changes to this repository are documented here.

## [1.1.0] - 2026-04-21

### Changed
- Commit `dist/` directory to repository for immediate user access
- Simplify installation instructions — clone and copy, no build required
- Add CI safeguard `build-sync` to ensure `dist/` stays in sync with source

### Documentation
- Update `README.md` with simplified clone-and-copy instructions
- Update `docs/SYNC-STRATEGY.md` with committed `dist/` approach
- Update `CONTRIBUTING.md` with rebuild-and-commit workflow

## [1.0.0] - 2026-04-21

### Added
- Initial repository setup with full structure
- `docker-expert` skill with two-file overlay pattern
- `catalog.yaml` machine-readable skill index
- `shared/` directory with EEA design foundations and style guide
- `workflows/` directory with multi-skill orchestration recipes
- `.github/workflows/validate-skills.yml` CI validation
- `CONTRIBUTING.md` with sync and override conventions
- `README.md` with overview and quick start

### Documentation
- EEA-style-guide.md placeholder
- design-foundations.md placeholder
- data-schemas.md placeholder
- data-report.md workflow placeholder