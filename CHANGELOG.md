# Changelog

All notable changes to this project will be documented in this file.

## [0.3.0] - 2026-02-12

### Added

- JSON pipeline commands for agent-driven document generation
  - `tmpltr fill <template> -d <json>` -- JSON to TOML content file
  - `tmpltr pipe <template> -d <json>` -- JSON to PDF directly (no intermediate files)
  - `tmpltr schema <template>` -- generate JSON schema from template
  - `--data <json>` flag on `tmpltr compile` for JSON overrides at compile time
  - `parse_json_input()` helper supports inline JSON, file path, or stdin (`-`)
- 7 new universal templates
  - **meeting-notes** -- structured meeting notes with attendees, agenda, decisions, action items
  - **cv** -- two-column resume with sidebar layout for contact/skills and main content
  - **business-card** -- standard 85x55mm cards, 8 per A4 sheet with cut layout
  - **shipping-label** -- sender/recipient address blocks with tracking and shipment details
  - **habit-tracker** -- landscape monthly grid with habits as rows and days as columns
  - **nda** -- mutual or unilateral non-disclosure agreement with default clauses and signatures
  - **contract** -- service agreement with scope, deliverables, milestones, payment terms
- 2 hand-drawn week calendar templates
  - **week-calendar** -- portrait A4 weekly planner with sketchy borders and notebook paper
  - **week-calendar-landscape** -- landscape A4 with 7-column day grid layout
- JSON schemas generated for all templates (invoice, formal-letter, report, certificate, and all new ones)
- All templates work with empty JSON `{}`, partial data, and full data
- All templates support brand overlays and `labels` for i18n

### Fixed

- Typst warning-only output no longer treated as compilation error (checks for `error:` prefix)
- `extract_fields` regex now captures `default:` and `type:` parameters from `#editable()` calls

### Changed

- Updated SKILL.md with JSON pipeline as primary workflow for agent-driven generation
- Updated README.md with JSON pipeline documentation

## [0.2.0]

- Initial public release

## [0.1.0]

- Initial commit
