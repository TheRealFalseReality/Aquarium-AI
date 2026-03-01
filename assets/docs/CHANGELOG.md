# Changelog

All notable changes to this project will be documented in this file.

## [3.0.10] - 2026-2-27 - Visual Updates, Stocking Tool Fixes

### Added

- Add visual contrast to buttons and chips throughout the app  
- Add FlexColorScheme themes, AppColorTheme palette picker, Appearance screen, and custom color picker  

### Fixed  

- Fix bug with species popup not reflecting common names  
- Fix AI Stocking tool re-navigation bug, improve species selection UX, and make tank size optional

**Full Changelog**: <https://github.com/TheRealFalseReality/Aquarium-AI/compare/v3.0.03...v3.0.10>

## [3.0.03] - 2026-2-24  - Major Updates

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

### Added (Soon)

- Fish, equipment and plants specific details with images
- Better & Modern parameter, Dosing UX/UI  
- Add detailed metrics per tank with custom metrics (last water change, fish count, algae level?)
- Stocking guides per tank  
- Notifications & Events log in calendar view  
- Expenses or P&L
- Share and import tanks with friends  
- Explore feed  
- iOS ( in_app_update -> upgrader)
- Make the parameter and dosing, well, all those screens better  
- Customize welcome screen  
- Allow user to edit prompts to further customize the app  
- Backup Photos  
- Add Sorting or global filters to fish types/species
- Add details for fish types and possibly species
- Reef Safe indicator
- Let's Start a Community!
- [**Suggest more!**](https://github.com/TheRealFalseReality/Aquarium-AI/issues) Request a Feature or report a bug  

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
