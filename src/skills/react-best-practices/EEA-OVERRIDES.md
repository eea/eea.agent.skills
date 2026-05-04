# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.0 -->
<!-- Last-Sync: 2026-05-04 -->

## EEA-Specific Patterns

### Placeholder

This file is a placeholder for future EEA-specific overrides to the upstream
react-best-practices skill. Currently, no overrides are needed as the upstream
guidelines are broadly applicable.

## EEA-Specific Considerations

### Server-Side Performance

When applying server-side performance rules in EEA contexts:

- EEA applications typically run on EEA-managed infrastructure, not Vercel
- Consider using EEA's internal caching layers instead of Vercel-specific features
- `after()` patterns may need adaptation for non-Vercel environments

### Bundle Size Optimization

- EEA applications may have different third-party library constraints
- Internal EEA packages should follow the same barrel file avoidance patterns

## Handoff to Other EEA Skills

When React best practices tasks are complete, consider these EEA skills:

- **`eea-design-system`** (future): EEA-specific UI components and patterns
- **`eea-accessibility`** (future): EEA accessibility compliance

## Notes

- Upstream source: https://github.com/vercel-labs/agent-skills
- License: MIT
