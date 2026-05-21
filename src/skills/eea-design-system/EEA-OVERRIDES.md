# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.0 -->
<!-- Last-Sync: 2026-05-21 -->

## EEA Logo Usage Rules

The Agency logo is the property of the EEA and is registered with WIPO (World
Intellectual Property Organisation). It may **not** be cropped or amended in any
other way. See the EEA's corporate identity manual for full graphical style
guidelines.

- **Journalistic use:** The logo may be reproduced for journalistic purposes in
  articles etc. without advance permission.
- **Other use:** Permission is required. Address requests via the EEA online
  form.
- **Co-branding:** The Agency normally allows use on products or services
  prepared jointly with other bodies, or in connection with events where it is a
  contributor or co-organiser.
- **Endorsement:** Requests to use the logo to endorse products, services,
  events or activities in which the EEA is not actively involved are normally
  declined.

### Legal Notice
Full legal notice: https://www.eea.europa.eu/en/legal-notice#eea-logo

## Corporate Identity Manual
The EEA's corporate identity manual provides a graphical style guide for EEA
reports and online services as well as guidelines for a coherent look of other
items produced by the Agency.

Reference: https://www.eea.europa.eu/en/newsroom/branding-materials

## Logo Component Documentation
For Logo component implementation details (variants, sizing, responsive
behavior), see:
https://eea.github.io/volto-eea-design-system/docs/webdev/Components/Logo/

## EEA Network Infrastructure

When applying design system assets in EEA contexts:

- Respect `HTTP_PROXY` and `HTTPS_PROXY` environment variables for external
  network calls.
- EEA applications run on EEA-managed infrastructure, not Vercel.
- Consider EEA's internal caching layers for static assets.

## Accessibility

EEA follows WCAG 2.1 Level AA as the minimum accessibility standard:

- All web applications must comply with **WCAG 2.1 Level AA**
- Reference: https://www.w3.org/WAI/WCAG21/quickref/
- EEA-specific accessibility checklist:
  - Keyboard navigation must work for all interactive elements
  - Color contrast ratios must meet 4.5:1 for normal text, 3:1 for large text
  - All images must have meaningful alt text
  - Forms must have proper labels and error handling
  - Focus indicators must be visible
  - Screen reader compatibility is required

## Notes

- Upstream source: https://github.com/eea/volto-eea-design-system
- License: MIT (design system code); EEA logo is EEA property per legal notice
