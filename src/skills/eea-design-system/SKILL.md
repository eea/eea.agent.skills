---
name: eea-design-system
description: >
  European Environment Agency design system for Volto-based web applications.
  Covers colors, typography, spacing, components, and branding assets.
  Use when generating, reviewing, or refactoring UI code for EEA projects.
license: MIT (design system code); EEA logo is EEA property per legal notice
metadata:
  version: "1.0.0"
  eeaspecific: "true"
  upstream: "https://github.com/eea/volto-eea-design-system"
---

# EEA Design System

**Version:** 1.0.0
**Source:** https://github.com/eea/volto-eea-design-system
**Docs:** https://eea.github.io/volto-eea-design-system/

> This skill governs how agents apply the EEA Design System when generating,
> reviewing, or refactoring UI code for EEA web applications.

---

## How to Use This Skill

1. **Read [references/DESIGN.md](references/DESIGN.md)** for the canonical design tokens
   (colors, typography, spacing, components).
2. **Use `assets/`** for official EEA and thematic platform logos.
3. **Follow `EEA-OVERRIDES.md`** for EEA-specific constraints (logo legal rules,
   proxy compliance, corporate identity manual links).
4. **Reference the Logo component page** for implementation details:
   https://eea.github.io/volto-eea-design-system/docs/webdev/Components/Logo/

---

## Agent Workflow

When a task involves UI, UX, or branding for an EEA project:

1. Load this skill.
2. Open [references/DESIGN.md](references/DESIGN.md) and apply the relevant tokens.
3. If logos are needed, pick the correct variant from `assets/` and respect
   the usage rules in `EEA-OVERRIDES.md`.
4. Ensure all color combinations meet WCAG 2.1 AA contrast ratios.
5. Prefer sharp edges (`border-radius: 0px`) unless the component variant
   explicitly requires rounding.
6. Use the 8px grid for spacing and sizing decisions.

---

## Asset Usage Quick Reference

| Asset | Use Case |
|-------|----------|
| `eea-logo.svg` | Primary EEA logo on light backgrounds |
| `eea-logo-white.svg` | EEA logo on dark/colored backgrounds |
| `eea_icon.png` | Favicon / app icon |
| `favicon.ico` | Browser favicon |
| `bise-logo.svg` / `bise-logo-white.svg` | Biodiversity Information System |
| `fise-logo.svg` / `fise-logo-white.svg` | Forest Information System |
| `wise-freshwater-logo.svg` / `wise-freshwater-logo-white.svg` | WISE Freshwater |
| `wise-marine-logo.svg` / `wise-marine-logo-white.svg` | WISE Marine |

---

## Key Constraints

- Never crop, amend, or distort EEA logos.
- Thematic platform logos follow the same legal rules as the main EEA logo.
- All public-facing applications must comply with WCAG 2.1 Level AA.
- Default `border-radius` is `0px` across the system.
- Typography: Roboto (fallback Arial), base 16px, bold for headings only.

---

## Handoff to Other EEA Skills

When design system tasks are complete, consider these EEA skills:

- **`eea-volto`** (future): EEA's Volto/Plone 6 frontend development
- **`eea-accessibility`** (future): Detailed EEA accessibility compliance
