# Changelog

All notable changes to this project will be documented in this file.

## [3.2.00] - 2026-3-10 • Fish Compatibility Browser & Onboarding

### Added

- **Fish Compatibility Browser** - check out the compatibility of the fish at a glance. I want to make the community help expand on this.
- **Add skippable 6-step onboarding flow** - you can revisit this in settings

### Changed

- Move tank header actions to FAB speed-dial; add TankInhabitantScreen with age chips, harmony delta, persistent filters, inhabitant edit/delete FAB, and quick-action speed-dial
- Migrate fish compatibility data to Cloud Firestore with Fish Compat Editor integration and local WebP images

### Removed

- Remove bundled fishcompat.json; use Firestore exclusively with SP cache fallback and retry UX

**Full Changelog**: https://github.com/TheRealFalseReality/Aquarium-AI/compare/v3.1.03...v3.2.00

## [3.1.03] - 2026-3-7 • UUIDs, Mostly Authorization Checks, Facebook Login support

### Changed

### ***Please Note:***
- **You MAY need to reset your storage in order for new data set to load. I added UUIDs to the fish types to allow for better changes in the future.**
- The rest is mostly backend updates.

**Full Changelog**: https://github.com/TheRealFalseReality/Aquarium-AI/compare/v3.1.00...v3.1.03

## [3.1.01] - 2026-3-3 • Perks, Community and Profile Features  

### Added

- **Add user profile section with social auth**
- **Founder Aquarist tier, modern Tank Showcase hero image, founder perks system, community post fixes**
- User-selectable font families in Appearance screen
- Add reef tank subtype for saltwater tanks with filter support
- Add fish data sorting and reef safety classification
- Add global TankTag registry with explicit backup/restore support
- Add single-tank share/import feature
- Welcome screen: 2-column grid with list/grid toggle + tank management grid/mosaic mode & card customization
- Add main tank banner photo to Tank Details screen
- Allow permanent dismissal of welcome screen header

### Changed

- Localize chatbot suggestion chips, add AI Response Language setting
- Localize AI compat, calculators, about, information, and AI provider settings screens
- Localize hardcoded strings across settings, drawer, welcome screen, AquaPi promo dialog, history screen, and more

**Full Changelog**: <https://github.com/TheRealFalseReality/Aquarium-AI/compare/v3.0.10...v3.1.00>

### Added

## [3.0.10] - 2026-2-27 • Visual Updates, Stocking Tool Fixes

### Added

- Add visual contrast to buttons and chips throughout the app
- Add FlexColorScheme themes, AppColorTheme palette picker, Appearance screen, and custom color picker

### Fixed

- Fix bug with species popup not reflecting common names
- Fix AI Stocking tool re-navigation bug, improve species selection UX, and make tank size optional

**Full Changelog**: <https://github.com/TheRealFalseReality/Aquarium-AI/compare/v3.0.03...v3.0.10>

## [3.0.03] - 2026-2-24 • Major Updates

### Added

- **Add developer Groq API key fallback with rate limiting; default provider → Groq**
  - **Enabled free in-app AI features!!** These are limited and may be disabled at any time. This uses Grok by default, it is not as good as Gemini, but it works. I encourage you to use your AI. I may increaze these limits or use other models if you like this app!
- **Buy me a Coffee!** Added option to remove ADs for **$0.99 USD** (for now). This is for what I call *"Founders Perks"*,  for those who like this app and want to support the development. I will remove the ADs and when I can, raise your limits on the Free AI!
- **Add Fish Info AI Tool**, dedicated result screen, and prominent tool chips to AI Chatbot card
- Add native share sheet for all AI analysis results
- Add theme colors throughout app UI with section grouping, enhanced Material You indicator, and compact Appearance section
- Add in-app changelog to Settings and Information screens with one-time update dialog
- Add AI Analysis History: persistent log with favorites and full report replay
- Add granular species selection dialog to Compatibility Tool
- Add species tags to tank inhabitants

### Changed

- Convert tank details and creation screens to tabbed navigation with theme-colored accents
- Enhance welcome screen card descriptions with specific feature details
- Rework edit inhabitant overlay: collapsible fish selector, top padding, smart name protection
- Reduce AI token consumption across all providers
- Fix unbounded token growth in all chat providers with configurable history limit
- Robust AI error handling: modern dialog, API key shortcuts, and rate-limit rollback on failure

### Removed

- Remove "Include Custom Names" from AI report dialogs

**Full Changelog**: <https://github.com/TheRealFalseReality/Aquarium-AI/compare/v2.1.04...v3.0.03>

## [Unreleased]

### To be Added

- Fish, equipment and plants specific details with images
- Better & Modern parameter, Dosing UX/UI
- Add detailed metrics per tank with custom metrics (last water change, fish count, algae level?)
- Stocking guides per tank
- Notifications & Events log in calendar view
- Expenses or P&L
- Explore feed
- iOS ( in_app_update -> upgrader)
- Make the parameter and dosing, well, all those screens better
- Allow user to edit prompts to further customize the app
- Backup Photos
- Add Sorting or global filters to fish types/species
- Add details for fish types and possibly species
- Reef Safe indicator
- User rearrange features
- User edited Prompts in your language
- Let's Start a Community!
- Allow tank info attachment for any post
- [**Suggest more!**](https://github.com/TheRealFalseReality/Aquarium-AI/issues) Request a Feature or report a bug

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).