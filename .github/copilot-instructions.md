# Copilot Instructions for Aquarium AI

## Project Overview

**Aquarium AI** (`fish_ai`) is a Flutter application (package name `fish_ai`) targeting Android, iOS, Web, macOS, Windows, and Linux. It provides AI-powered tools for aquarium hobbyists: fish compatibility checker, AI chatbot, photo analyzer, stocking assistant, aquarium calculators, tank management, parameter logging, and dosing logger.

Current version: `3.0.10+3.0.10` (see `pubspec.yaml`).

---

## Tech Stack

| Layer | Technology |
| ----- | ---------- |
| UI framework | Flutter (Material 3, `flex_color_scheme`) |
| State management | Riverpod (`flutter_riverpod`, `riverpod_annotation`) |
| AI providers | Google Gemini (`google_generative_ai`), OpenAI (`dart_openai`), Groq (`groq`) |
| Backend | Firebase (Analytics, Crashlytics, Remote Config, Hosting) |
| Ads | Google Mobile Ads |
| Persistence | `shared_preferences` |
| Localization | Flutter `intl` / ARB files (`flutter_localizations`, `flutter gen-l10n`) |
| Notifications | `flutter_local_notifications` |
| Charts | `fl_chart` |
| Theming | `flex_color_scheme` v8 + `dynamic_color` (Material You) |

---

## Repository Layout

```text
  main.dart               # App entry point; Firebase init with retry, route definitions
  main_layout.dart        # Shared Scaffold wrapper (AppBar + drawer + body)
  constants.dart          # AdMob IDs, product IDs, developer Groq key (--dart-define)
  theme_provider.dart     # AppColorTheme enum (15 values), AppFont enum, ThemeProviderNotifier
  theme_colors.dart       # AquaThemeColors – all seed colour constants
  firebase_options.dart   # Auto-generated Firebase config
  l10n_template.arb       # Template for new translation files
  l10n/                   # ARB localisation files (app_en.arb is the source of truth)
    app_en.arb            # English strings (source of truth)
    app_de.arb            # German
    app_es.arb            # Spanish
    app_fr.arb            # French
  models/                 # Plain Dart data classes (Tank, Fish, WaterParameter, etc.)
  providers/              # Riverpod providers for app state
  screens/                # Full-page widgets (one file per screen)
  services/               # Platform/external service wrappers
  widgets/                # Reusable widget components
  prompts/                # AI prompt builder classes
  mixins/                 # Dart mixins shared across screens
  utils/                  # Utility/helper functions
  examples/               # Example data files
assets/                   # Images, fonts, JSON data, documentation markdown files
  docs/
    en/                   # All English docs (source of truth for user-facing; dev-only)
      USER_GUIDE_en.md        # English user guide
      HELP_WANTED_en.md       # English contributor recruitment doc
      CHANGELOG_en.md         # English changelog
      CONTRIBUTING_en.md
      START_HERE_I18N_en.md
      TRANSLATION_GUIDE_en.md
      TRANSLATION_QUICK_REF_en.md
      LOCALIZATION_DEV_GUIDE_en.md
      TESTING_I18N_en.md
      I18N_IMPLEMENTATION_en.md
    de/                   # German translations of user-facing docs
      USER_GUIDE_de.md
      HELP_WANTED_de.md
      CHANGELOG_de.md
    es/                   # Spanish translations of user-facing docs
      USER_GUIDE_es.md
      HELP_WANTED_es.md
      CHANGELOG_es.md
    fr/                   # French translations of user-facing docs
      USER_GUIDE_fr.md
      HELP_WANTED_fr.md
      CHANGELOG_fr.md
scripts/
  validate_translations.sh  # Bash script; checks ARB key completeness and placeholder parity
test/                     # Flutter unit/widget tests (run with `flutter test`)
.github/
  workflows/
    android-release-build.yml      # Triggered on release; builds signed AAB/APK
    firebase-hosting-merge.yml     # Deploys web build to Firebase Hosting on push to main
    firebase-hosting-pull-request.yml  # Preview deploy for PRs
    validate-translations.yml      # Validates ARB JSON syntax + key completeness on PR/push
```

---

## Development Commands

```bash
# Install dependencies
flutter pub get

# Generate localization files (run after editing any .arb file)
flutter gen-l10n

# Run static analysis (linter)
flutter analyze

# Run tests
flutter test

# Run app (web)
flutter run -d chrome

# Run app with developer Groq key
flutter run --dart-define=DEVELOPER_GROQ_API_KEY=gsk_your_key_here

# Build web (production)
flutter build web --dart-define=DEVELOPER_GROQ_API_KEY=gsk_your_key_here

# Build Android AAB (production flavour)
flutter build appbundle --flavor production --release \
  --dart-define=DEVELOPER_GROQ_API_KEY=gsk_your_key_here

# Validate translation files
chmod +x scripts/validate_translations.sh
./scripts/validate_translations.sh
```

> **Note:** The generated localization files live in `.dart_tool/flutter_gen/gen_l10n/` and are **not** committed to Git. Always run `flutter gen-l10n` after editing any `.arb` file.

---

## Key Architecture Patterns

### State Management (Riverpod)

- All global state lives in `lib/providers/`. Every provider is a `StateNotifier` or `AsyncNotifier`.
- `themeProviderNotifierProvider` (in `theme_provider.dart`) controls theme mode, color theme, and font family. It persists state via `SharedPreferences`.
- Use `ref.watch()` in `ConsumerWidget`s and `ref.read()` for one-shot mutations.

### Theming

- **`AppColorTheme`** enum has 15 values:
  `defaultTheme`, `materialYou`, `oceanBlue`, `iceBlue`, `gold`, `mulberry`, `midnight`,
  `orange`, `green`, `skyBlue`, `royalBlue`, `orchid`, `hotPink`, `crimson`, `custom`.
- Seed colours are defined in `lib/theme_colors.dart` (`AquaThemeColors` class).
- `lib/main.dart` builds `FlexThemeData.light/dark()` using `FlexSchemeColor.from(primary: seedColor)` for non-Material-You themes, and `ThemeData` with a dynamic `ColorScheme` for Material You.
- When adding a new theme, you must update: `AppColorTheme` enum, `AppColorThemeExt.seedColor`, `AppColorThemeExt.displayName`, `AquaThemeColors`, the swatch maps in `appearance_screen.dart`, and `_buildFlexTheme` in `main.dart`.
- The `custom` theme uses a user-picked seed colour stored as `customSeedColor` in `ThemeProviderState`.
- Persist theme by **name** (`colorThemeName` SharedPreferences key) not index, to survive enum reordering.

### Fonts

- **`AppFont`** enum: `poppins`, `karla`, `notoSans`. Persisted via `appFont` SharedPreferences key.
- Font families must match names in `pubspec.yaml` fonts section.

### Localization (i18n)

- **All user-visible strings must be localized.** Never use bare string literals in widget trees.
- Template: `lib/l10n/app_en.arb` (source of truth). When adding a new string:
  1. Add the key/value + `@key` metadata to `app_en.arb`.
  2. Add translated versions to `app_de.arb`, `app_es.arb`, `app_fr.arb` (translate to best ability).
  3. Run `flutter gen-l10n` to regenerate `AppLocalizations`.
  4. Use `AppLocalizations.of(context)!.yourNewKey` in widgets (or `l10n.yourNewKey` if `l10n` alias is set up in the screen).
- Placeholders use `{paramName}` syntax in ARB files. Ensure all translations carry the same placeholders as the English template.
- The `validate-translations.yml` workflow checks JSON validity and key completeness for every PR touching `lib/l10n/**.arb`. Warnings (missing keys) do **not** fail the build, but errors (invalid JSON) do.
- The `l10n_template.arb` file at the repo root is a copy-and-translate starting point for new languages.
- **Strings that are not visible to users** (analytics event names, SharedPreferences keys, JSON field names, route names, debug-only labels) do **not** need to be localized.

### Text Overflow Prevention

Translated strings are often longer than their English originals. Always design layouts to handle variable-length text:

- **In `Row` widgets:** Wrap `Text` (and any widget that displays text) in `Flexible` or `Expanded` so it can wrap or truncate instead of overflowing. Never place a bare `Text` as a direct child of `Row` when the text length is unbounded.
- **In `Row` heading widgets** (e.g., icon + label rows in section headers or card titles): wrap the `Text` in `Flexible`.
- **Buttons next to text in a `Row`:** If the combined content can be long (e.g., label + restore button), place the button on a new line using a `Column` instead of a `Row`.
- **`PopupMenuButton` items:** Always wrap item `Text` widgets in `Flexible` inside their `Row` to prevent overflow in narrow menus.
- **`ListTile` subtitles:** Do not set `maxLines: 1` / `overflow: TextOverflow.ellipsis` unless truncation is intentional. Allow subtitles to wrap for longer translations.
- **Card/dialog titles:** Wrap in `Flexible` if inside a `Row`; rely on `Text` natural wrapping if standalone.

### Models

- Plain Dart classes in `lib/models/`. Most implement `toJson()` / `fromJson()`.
- `TankTag` supports both the new `{name, color}` map format **and** the legacy plain-string format in `fromJson()` for backwards compatibility. `color` is a nullable ARGB `int`; `null` means "use theme secondary colour at render time".
- Use `uuid` package for ID generation (`const Uuid().v4()`).

### Services

- `lib/services/` wraps external services (Firebase, ads, in-app purchases, notifications, etc.).
- `InAppUpdateService` no-ops gracefully on non-Android/web platforms; call its methods without platform guards.
- `RemoteConfigService` gates feature flags and fish data updates.
- `AnalyticsService` and `CrashlyticsService` are safe to call unconditionally (they guard internally when Firebase is not initialized).

### Screens

- Each screen in `lib/screens/` is typically a `ConsumerStatefulWidget` or `ConsumerWidget`.
- Use `MainLayout` wrapper (`lib/main_layout.dart`) for full-page screens to get the shared AppBar and drawer.
- To avoid Flutter `ListTile`/`ExpansionTile` layout assertion errors, always give `leading` widgets explicit size constraints (e.g., `SizedBox(width: 48, height: 48, …)` or `Container(width: 40, height: 40, …)`).

### Firebase Initialization

- Firebase is initialized in `main.dart` with an exponential-backoff retry loop (up to 3 attempts) to handle intermittent `HandshakeException` / `SocketException` errors in CI or restricted network environments.
- A global `_firebaseInitialized` flag is checked before using Firebase services.

---

## Localization Conventions (Important for Every PR)

When any PR adds or modifies user-visible strings:

1. **Add to `app_en.arb`** with an `@key` metadata block:

   ```json
   "myNewKey": "My new string with {param}",
   "@myNewKey": {
     "description": "Description of where this string appears",
     "placeholders": {
       "param": {"type": "String"}
     }
   }
   ```

2. **Add to all other `.arb` files** (`app_de.arb`, `app_es.arb`, `app_fr.arb`) with your best translation. Use the same placeholder names.
3. **Run `flutter gen-l10n`** to verify generation succeeds without errors.
4. **Use `AppLocalizations.of(context)!.myNewKey`** in the widget.

---

## CI / Workflows

| Workflow | Trigger | What it does |
| -------- | ------- | ------------ |
| `validate-translations.yml` | PR / push to `main` (paths: `lib/l10n/**`) | Validates JSON syntax + key completeness of all `.arb` files |
| `firebase-hosting-pull-request.yml` | Pull request | Builds web app and deploys preview to Firebase Hosting |
| `firebase-hosting-merge.yml` | Push to `main` | Deploys web app to production Firebase Hosting |
| `android-release-build.yml` | Release event | Builds signed production + staging AAB/APK and uploads to release assets |

The Firebase Hosting PR workflow requires the `FIREBASE_SERVICE_ACCOUNT_FISH_AI_CE60C` secret (not available in forks). If this is `action_required`, that's expected for external contributors and does not indicate a code bug.

The Android release workflow requires `KEY_PROPERTIES`, `KEYSTORE_BASE64`, and `DEVELOPER_GROQ_API_KEY` secrets.

---

## Known Errors and Workarounds

### Firebase HandshakeException / SocketException in CI

- **Symptom:** Firebase initialization fails with TLS or network errors during `flutter test` or web builds in CI.
- **Workaround:** `main.dart` already handles this with a 3-attempt exponential-backoff retry and degrades gracefully (app runs without Firebase features). No additional action required.

### Flutter ListTile/ExpansionTile Leading Widget Layout Assert

- **Symptom:** `BoxConstraints forces an infinite width/height` or `RenderBox was not laid out` assertions when using image/icon widgets as `leading`.
- **Workaround:** Wrap the leading widget in a `SizedBox(width: 48, height: 48, child: …)` or `Container(width: 40, height: 40, child: …)`.

### Localization Code Generation Errors

- **Symptom:** `flutter gen-l10n` fails because a key exists in a translation `.arb` file but not in `app_en.arb`, or a placeholder name differs.
- **Workaround:** Ensure `app_en.arb` is the source of truth. All keys and placeholder names in non-English ARB files must exactly match those in `app_en.arb`.

### `colorSchemeSeed` vs `FlexSchemeColor.from()`

- **Symptom:** Build error or unexpected theme colours when using `colorSchemeSeed:` parameter on `FlexThemeData`.
- **Workaround:** Use `colors: FlexSchemeColor.from(primary: seedColor)` (not `colorSchemeSeed`) with `flex_color_scheme` v8.

### Firebase Hosting Preview Workflow Requires Approval

- **Symptom:** The `firebase-hosting-pull-request.yml` workflow shows `action_required` for PRs from bots/forks.
- **Workaround:** This is a Firebase Hosting security gate. A repository owner must manually approve the deployment. It does not reflect a code issue.

---

## Adding a New Theme

1. Add a new value to `AppColorTheme` enum in `lib/theme_provider.dart`.
2. Add its seed colour constant to `AquaThemeColors` in `lib/theme_colors.dart`.
3. Add a `case` in `AppColorThemeExt.seedColor` and `AppColorThemeExt.displayName`.
4. Add entries to the swatch maps in `lib/screens/appearance_screen.dart`.
5. Add a `case` in `_themeLocalizedName()` in `lib/screens/appearance_screen.dart` and add a `theme<Name>` key to all four ARB files.
6. Add a `case` in `_buildFlexTheme` in `lib/main.dart` if the theme needs special handling.

---

## Adding a New Tool

When adding a new AI tool, calculator, or other significant feature:

1. Create the screen in `lib/screens/my_tool_screen.dart` (see [Adding a New Screen](#adding-a-new-screen)).
2. Register its named route in `lib/main.dart`.
3. Add a feature card or navigation entry so it is discoverable (welcome screen, drawer, or information screen).
4. **Update `assets/docs/en/USER_GUIDE_en.md`** to document the new tool:
   - Add a new section under the appropriate heading (AI Tools, Calculators, Tank Tools, etc.).
   - Explain all inputs, outputs, and any prerequisites (e.g. API key requirement).
   - Add the section to the **Table of Contents** at the top of the file.
5. Add any new user-visible strings to all `.arb` files (see [Localization Conventions](#localization-conventions-important-for-every-pr)).
6. Log tool usage with `AnalyticsService.logFeatureUsed(featureName: 'my_tool', ...)` where appropriate.

---

## Keeping the User Guide Up to Date

`assets/docs/en/USER_GUIDE_en.md` is the single source of truth for end-user documentation.
**Any PR that changes how a tool works must also update the corresponding section of
the User Guide and its translations.**

Update the User Guide when you:

| Change | What to update in `USER_GUIDE_en.md` |
| ------ | --------------------------------- |
| Add a new input field or option | Add it to the tool's **Inputs** / **How to Use** list |
| Remove or rename a field | Remove or rename it in the same list |
| Change a prerequisite (e.g. now requires an API key, or no longer does) | Update the **Requires** line at the top of that section |
| Rename a screen or route | Update the **Route** line and any cross-references |
| Add or remove a calculator | Add/remove the row in the Calculators table |
| Change outputs or report format | Update the "Reading the Report" / result description |
| Rename a setting or move it to a different settings group | Update the Settings & Appearance table |

If the change is purely internal (refactor, performance, bug fix with no UX impact)
no User Guide update is needed.

---

## Markdown Authoring Rules

All `.md` files in this repository must pass `markdownlint` using the repo-root
`.markdownlint.json` config. Run the linter before committing any markdown change:

```bash
# Install once (requires Node.js)
npm install -g markdownlint-cli

# Lint a single file
markdownlint --config .markdownlint.json path/to/file.md

# Auto-fix what can be fixed automatically
markdownlint --fix --config .markdownlint.json path/to/file.md
```

### Rules enforced (and notable exceptions)

| Rule | Status | Notes |
| ---- | ------ | ----- |
| MD013 line-length | **disabled** | Technical docs contain long URLs and code |
| MD024 no-duplicate-heading | **disabled** | Changelogs repeat "Added"/"Fixed" per version |
| All other default rules | **enabled** | Blanks around headings, lists, fences; table style; etc. |

### Table formatting

Use the **compact spaced** style – separator rows must have a space on each side of
every dash group:

```markdown
| Header A | Header B |
| -------- | -------- |
| cell     | cell     |
```

### Fenced code blocks

Always specify a language after the opening triple-backtick. Example:
```` ```dart // your code here ``` ````

---

## Translating Documentation (User-Facing Docs)

The following docs in `assets/docs/` are displayed inside the app and must have
translated versions for German (`de`), Spanish (`es`), and French (`fr`):

| English source | Description |
| -------------- | ----------- |
| `assets/docs/en/USER_GUIDE_en.md` | In-app user guide |
| `assets/docs/en/HELP_WANTED_en.md` | Contributor recruitment page |
| `assets/docs/en/CHANGELOG_en.md` | Release changelog |

### File naming convention

Files follow the pattern `{DOCNAME}_{locale}.md` inside `assets/docs/{locale}/`:

- `assets/docs/en/USER_GUIDE_en.md` (English source of truth)
- `assets/docs/de/USER_GUIDE_de.md` (German)
- `assets/docs/es/USER_GUIDE_es.md` (Spanish)
- `assets/docs/fr/USER_GUIDE_fr.md` (French)

The app loads the locale-appropriate file at runtime with a fallback to the English
original (`assets/docs/en/{DOCNAME}_en.md`).

### When to update translations

- **Any PR that modifies a user-facing English doc** must also update (or create) the
  corresponding file in all three locale subdirectories.
- Translate to best ability; machine-assisted translation is acceptable as a starting
  point, but review for accuracy.
- Keep the same markdown structure (headings, lists, tables, code fences) as the
  English source so the app renders correctly.
- All translated files must pass `markdownlint --config .markdownlint.json`.

### Developer-only docs (no translation needed)

These docs are not shown in the app UI and do **not** need translated copies:

- `CONTRIBUTING_en.md`, `START_HERE_I18N_en.md`, `TRANSLATION_GUIDE_en.md`
- `TRANSLATION_QUICK_REF_en.md`, `LOCALIZATION_DEV_GUIDE_en.md`
- `TESTING_I18N_en.md`, `I18N_IMPLEMENTATION_en.md`

---

## External Variables – Constants & Remote Config Convention

**All URLs, default model names, feature flags, rate limits, and any other externally-sourced or remotely-configurable values must be declared as named constants** rather than being written as inline literals in business logic or UI code.

### Where to put each type of constant

| Type of value | Where to declare it |
| ------------- | ------------------- |
| Build-time secrets (API keys injected via `--dart-define`) | `lib/constants.dart` using `String.fromEnvironment(...)` |
| Static app-wide IDs (AdMob, in-app purchase product IDs) | `lib/constants.dart` |
| Remote Config **key names** | `RemoteConfigKeys` class in `lib/services/remote_config_service.dart` |
| Remote Config **in-app fallback defaults** | Top-level `_default*` private constants in `lib/services/remote_config_service.dart` |
| Default AI model names (overridable via Remote Config) | `_default*` constants in `lib/services/remote_config_service.dart` |
| External URLs that may change without an app update | Remote Config key + `_default*` fallback in `lib/services/remote_config_service.dart` |

### Rules

- **Never hard-code a URL, model name, or rate limit inline.** Always reference the named constant or the Remote Config getter.
- When adding a new Remote Config key:
  1. Add the key string as a `static const String` on `RemoteConfigKeys`.
  2. Add a `_default*` fallback constant above the class (document its expected format in a comment).
  3. Register the default in `RemoteConfigService.initialize()` inside `setDefaults({...})`.
  4. Expose a typed getter on `RemoteConfigService` (e.g. `static String get myNewValue`).
- When adding a new `--dart-define` build-time variable:
  1. Declare it in `lib/constants.dart` with `String.fromEnvironment('MY_VAR', defaultValue: '')`.
  2. Add it to all relevant `flutter run` / `flutter build` commands in the project README and in `.github/workflows/` where it is used.
  3. **Never commit the actual secret value**; it must live only in GitHub Secrets and local build environments.

### Example

```dart
// lib/constants.dart
const String myExternalServiceUrl =
    String.fromEnvironment('MY_SERVICE_URL', defaultValue: 'https://example.com/api');
```

```dart
// lib/services/remote_config_service.dart

// In-app fallback default
const String _defaultMyFeatureModel = 'my-model-v1';

class RemoteConfigKeys {
  /// String — model to use for My Feature.
  static const String myFeatureModel = 'my_feature_model';
}

class RemoteConfigService {
  // In initialize():
  //   RemoteConfigKeys.myFeatureModel: _defaultMyFeatureModel,

  static String get myFeatureModel =>
      _instance?.getString(RemoteConfigKeys.myFeatureModel) ??
      _defaultMyFeatureModel;
}
```

---

## Adding a New Screen

1. Create `lib/screens/my_screen.dart` as a `ConsumerStatefulWidget` (or `ConsumerWidget`).
2. Wrap content with `MainLayout(title: l10n.myScreenTitle, child: …)`.
3. Register a named route in `lib/main.dart` (the `routes:` map in `MaterialApp`).
4. Add a navigation entry to `lib/widgets/app_drawer.dart` if it should appear in the side drawer.
5. Add any new user-visible strings to all `.arb` files (see Localization section).

---

## Developer Groq API Key

The app supports a developer-provided Groq API key as a free fallback for users who haven't entered their own key. It is injected at build time:

```bash
flutter run --dart-define=DEVELOPER_GROQ_API_KEY=gsk_your_key_here
```

- **Never commit the key to the repository.** It lives only in GitHub Secrets (`DEVELOPER_GROQ_API_KEY`) and local build environments.
- The constant is declared in `lib/constants.dart`:

  ```dart
  const String developerGroqApiKey =
      String.fromEnvironment('DEVELOPER_GROQ_API_KEY', defaultValue: '');
  ```

- If empty, the app simply requires users to supply their own API key.
