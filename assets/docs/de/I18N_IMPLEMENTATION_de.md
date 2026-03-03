# Zusammenfassung der Internationalisierung (i18n)

## Übersicht

Aquarium AI unterstützt jetzt Internationalisierung, sodass die Community die App einfach in beliebige Sprachen übersetzen kann. Dieses Dokument fasst die Implementierung zusammen.

## Was wurde implementiert

### 1. Kerninfrastruktur

- **Flutter i18n-System**: Verwendet das integrierte Flutter-Paket `flutter_gen-l10n`
- **ARB-Dateien**: Application Resource Bundle (ARB)-Format zum Speichern von Übersetzungen
- **Code-Generierung**: Automatische Generierung von typsicherem Lokalisierungscode

### 2. Konfigurationsdateien

| Datei | Zweck |
| ---- | ------- |
| `l10n.yaml` | Konfiguration für die l10n-Code-Generierung |
| `pubspec.yaml` | Aktualisiert mit `generate: true` und Abhängigkeiten |
| `lib/main.dart` | Lokalisierungsdelegaten und unterstützte Sprachregionen konfiguriert |

### 3. Übersetzungsdateien

| Sprache | Datei | Status |
| -------- | ---- | ------ |
| Englisch | `lib/l10n/app_en.arb` | ✅ Vollständig (Vorlage) |
| Spanisch | `lib/l10n/app_es.arb` | ✅ Vollständig |
| Französisch | `lib/l10n/app_fr.arb` | ✅ Vollständig |
| Deutsch | `lib/l10n/app_de.arb` | ✅ Vollständig |
| Vorlage | `lib/l10n_template.arb` | Vorlage für neue Sprachen |

**Übersetzte Zeichenfolgen insgesamt**: 50+ benutzerseitige Zeichenfolgen

### 4. Aktualisierte Screens/Widgets

Die folgenden Dateien wurden aktualisiert, um lokalisierte Zeichenfolgen zu verwenden:

- ✅ `lib/screens/welcome_screen.dart` – Willkommensbildschirm mit allen Funktionen
- ✅ `lib/widgets/app_drawer.dart` – Navigationsleiste
- ✅ `lib/screens/settings_screen.dart` – Einstellungsfehlermeldungen

### 5. Dokumentation

| Dokument | Zweck |
| -------- | ------- |
| `TRANSLATION_GUIDE.md` | Umfassender Leitfaden für Übersetzer |
| `TRANSLATION_QUICK_REF.md` | Kurzreferenz für häufige Szenarien |
| `LOCALIZATION_DEV_GUIDE.md` | Entwicklerleitfaden zur Verwendung von l10n im Code |
| `TESTING_I18N.md` | Testleitfaden für die i18n-Implementierung |
| `CONTRIBUTING.md` | Allgemeine Richtlinien für Beiträge |
| Projekt-README (Root) | Aktualisiert mit Übersetzungsinformationen |

### 6. Werkzeuge

- **Validierungsskript**: `scripts/validate_translations.sh` – Validiert ARB-Dateien auf Vollständigkeit

## Wie es funktioniert

### Für Entwickler

```dart
// Import the generated localizations
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Use in widgets
final l10n = AppLocalizations.of(context)!;
Text(l10n.welcomeTitle)  // Shows "Welcome" in English, "Bienvenido" in Spanish, etc.
```

### Für Übersetzer

1. `lib/l10n_template.arb` nach `lib/l10n/app_XX.arb` kopieren (XX = Sprachcode)
2. Alle Werte übersetzen (nicht die Schlüssel)
3. `lib/main.dart` aktualisieren, um die neue Sprachregion hinzuzufügen
4. Einen Pull Request einreichen

## Unterstützte Sprachregionen

Aktuell in `lib/main.dart` konfiguriert:

```dart
supportedLocales: const [
  Locale('en'), // English
  Locale('es'), // Spanish  
  Locale('fr'), // French
  Locale('de'), // German
],
```

## Hauptfunktionen

### 1. Platzhalter

Unterstützung für dynamische Werte:

```json
"totalTanks": "Total: {count}"
```

Verwendung:

```dart
Text(l10n.totalTanks(tankCount))
```

### 2. Beschreibungen

Alle Zeichenfolgen enthalten Beschreibungen für den Kontext:

```json
"@welcomeTitle": {
  "description": "Title for the welcome screen"
}
```

### 3. Typsicherheit

Der generierte Code ist typsicher. Der Compiler erkennt:

- Falsch benannte Schlüssel
- Fehlende Übersetzungen
- Falsche Parameter

## Dateistruktur

```text
Aquarium-AI/
│   │   ├── app_en.arb           # English (template)
│   │   ├── app_es.arb           # Spanish
│   │   ├── app_fr.arb           # French
│   │   └── app_de.arb           # German
│   └── main.dart                # Localization configuration
├── lib/l10n_template.arb        # Template for new languages
├── l10n.yaml                    # l10n generation config
├── scripts/
│   └── validate_translations.sh # Validation tool
├── TRANSLATION_GUIDE.md         # For translators
├── TRANSLATION_QUICK_REF.md     # Quick reference
├── LOCALIZATION_DEV_GUIDE.md    # For developers
├── TESTING_I18N.md              # Testing guide
├── CONTRIBUTING.md              # Contribution guide
└── README.md                    # Updated with i18n info
```

## Generierte Dateien (nicht in Git)

Beim Ausführen von `flutter gen-l10n` werden diese Dateien generiert:

```text
.dart_tool/flutter_gen/gen_l10n/
├── app_localizations.dart       # Main localizations class
├── app_localizations_en.dart    # English implementation
├── app_localizations_es.dart    # Spanish implementation
├── app_localizations_fr.dart    # French implementation
└── app_localizations_de.dart    # German implementation
```

## Eine neue Sprache hinzufügen

### Schnelle Schritte

1. **ARB-Datei erstellen**: `lib/l10n/app_XX.arb` (XX = Sprachcode)
2. **Zeichenfolgen übersetzen**: Von der Vorlage kopieren, Werte übersetzen
3. **main.dart aktualisieren**: `Locale('XX')` zu `supportedLocales` hinzufügen
4. **Code generieren**: `flutter gen-l10n` ausführen
5. **Testen**: Gerätesprache ändern und überprüfen
6. **PR einreichen**: Mit der neuen ARB-Datei und den main.dart-Änderungen

### Beispiel: Japanisch hinzufügen

1. `lib/l10n/app_ja.arb` erstellen
2. `lib/main.dart` aktualisieren:

   ```dart
   supportedLocales: const [
     Locale('en'),
     Locale('es'),
     Locale('fr'),
     Locale('de'),
     Locale('ja'), // Add this
   ],
   ```

3. `flutter gen-l10n` ausführen
4. Testen und einreichen

## Aktuelle Abdeckung

### Bildschirme

- ✅ Willkommensbildschirm (vollständig)
- ✅ App-Navigationsleiste (vollständig)
- ⚠️ Einstellungsbildschirm (teilweise – nur Fehlermeldungen)
- ❌ Andere Bildschirme (noch nicht lokalisiert)

### Komponenten

- ✅ Funktionsnamen und -beschreibungen
- ✅ Navigationselemente
- ✅ Fehlermeldungen (in den Einstellungen)
- ⚠️ Allgemeine Schaltflächen (Speichern, Abbrechen usw. – definiert, aber noch nicht alle verwendet)
- ❌ Viele weitere UI-Elemente

## Nächste Schritte

### Für die weitere Implementierung

1. **Weitere Bildschirme lokalisieren**:
   - Info-Bildschirm
   - Rechnerbildschirme
   - Fischanpassungsbildschirm
   - Becken-Verwaltungsbildschirme
   - Alle anderen Bildschirme

2. **Weitere Widgets lokalisieren**:
   - Dialognachrichten
   - Tooltips
   - Hilfetexte
   - Schaltflächenbeschriftungen überall

3. **Weitere Sprachen hinzufügen**:
   - Portugiesisch (pt)
   - Italienisch (it)
   - Japanisch (ja)
   - Chinesisch (zh)
   - Russisch (ru)
   - Und mehr…

4. **Testen**:
   - Auf echten Geräten testen
   - Überprüfen, ob alle Sprachen korrekt angezeigt werden
   - Textüberlauf/Abschneidung prüfen
   - RTL-Sprachen testen (falls hinzugefügt)

5. **Automatisierung**:
   - CI/CD-Validierung hinzufügen
   - Automatisiertes Testen
   - Überprüfungen der Übersetzungsvollständigkeit

## Community-Beitrag

### Wie man beiträgt

1. **Übersetzen**: Übersetzungen hinzufügen oder verbessern (siehe `TRANSLATION_GUIDE.md`)
2. **Code lokalisieren**: Weitere Bildschirme auf `AppLocalizations` aktualisieren
3. **Testen**: In verschiedenen Sprachen testen und Probleme melden
4. **Dokumentieren**: Dokumentation verbessern

### Danksagungen

Alle Übersetzer werden genannt in:

- App-Info-Bildschirm
- README.md
- Release-Notizen

## Vorteile

### Für Benutzer

- ✅ App in ihrer Muttersprache
- ✅ Besseres Verständnis der Funktionen
- ✅ Zugänglicher für Nicht-Englischsprachige

### Für Entwickler

- ✅ Typsicherer Zugriff auf Zeichenfolgen
- ✅ Compiler erkennt fehlende Übersetzungen
- ✅ Einfach zu pflegen
- ✅ Standard-Flutter-Ansatz

### Für die Community

- ✅ Einfach Übersetzungen beizutragen
- ✅ Keine Programmierkenntnisse erforderlich
- ✅ Klare Dokumentation
- ✅ Validierungswerkzeuge vorhanden

## Technische Details

### Abhängigkeiten

In `pubspec.yaml` hinzugefügt:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  # ... other dependencies

dev_dependencies:
  # ... other dev dependencies
```

### Konfiguration

`l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

### Code-Generierungsbefehl

```bash
flutter gen-l10n
```

Dieser Befehl wird automatisch von `flutter run` und `flutter build` ausgeführt.

## Fehlerbehebung

### Fehlende Paketfehler

Wenn folgende Fehler auftreten:

- `'package:flutter_localizations/flutter_localizations.dart' not found`
- `'package:flutter_gen/gen_l10n/app_localizations.dart' not found`

**Lösung:**

1. **Abhängigkeiten installieren**:

   ```bash
   flutter pub get
   ```

2. **Lokalisierungsdateien generieren**:

   ```bash
   flutter gen-l10n
   ```

   Die generierten Dateien befinden sich in `.dart_tool/flutter_gen/gen_l10n/`

3. **Einrichtung überprüfen**:
   - Sicherstellen, dass `pubspec.yaml` `flutter_localizations: sdk: flutter` enthält
   - Sicherstellen, dass `l10n.yaml` mit der richtigen Konfiguration vorhanden ist
   - Sicherstellen, dass `flutter: generate: true` in `pubspec.yaml` gesetzt ist

4. **IDE/Editor neu starten** nach der Ausführung der obigen Befehle

**Hinweis**: Die generierten Lokalisierungsdateien werden nicht in Git committed. Sie werden automatisch generiert, wenn `flutter pub get` oder `flutter run` ausgeführt wird.

## Ressourcen

- [Offizielle Flutter i18n-Dokumentation](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [ARB-Dateiformat](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
- [ISO 639-1 Sprachcodes](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)

## Support

Bei Fragen oder Problemen:

- Dokumentation in diesem Repository prüfen
- Ein GitHub-Issue eröffnen
- `CONTRIBUTING.md` für Richtlinien beachten

## Lizenz

Alle Übersetzungen unterliegen derselben Lizenz wie das Hauptprojekt (MIT-Lizenz).

---

**Zuletzt aktualisiert**: 2025-10-18
**Implementierungsstatus**: ✅ Kerninfrastruktur abgeschlossen, bereit für Community-Beiträge
**Unterstützte Sprachen**: 4 (en, es, fr, de)
**Lokalisierte Bildschirme**: 3 (teilweise)
**Übersetzbare Zeichenfolgen insgesamt**: 50+
