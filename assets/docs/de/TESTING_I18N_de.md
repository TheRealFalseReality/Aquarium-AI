# Testleitfaden für Internationalisierung

Dieser Leitfaden erklärt, wie die Internationalisierungsimplementierung in Aquarium AI getestet wird.

## Voraussetzungen

- Flutter SDK installiert
- Aquarium AI-Projekt geklont
- Abhängigkeiten installiert: `flutter pub get`

## Lokalisierungscode generieren

Vor dem Testen den Lokalisierungscode generieren:

```bash
flutter gen-l10n
```

Dieser Befehl:

- Liest ARB-Dateien aus `lib/l10n/`
- Generiert Dart-Code in `.dart_tool/flutter_gen/gen_l10n/`
- Erstellt die `AppLocalizations`-Klasse und sprachspezifische Implementierungen

## Testmethoden

### 1. Gerätesprache ändern

**Auf Android-Emulator:**

1. Einstellungen öffnen
2. Zu System > Sprache und Eingabe > Sprachen navigieren
3. Testsprache hinzufügen und auswählen (z. B. Spanisch, Französisch, Deutsch)
4. App neu starten
5. Überprüfen, ob übersetzte Zeichenketten korrekt angezeigt werden

**Auf iOS-Simulator:**

1. Einstellungen öffnen
2. Zu Allgemein > Sprache und Region navigieren
3. Testsprache auswählen
4. App neu starten
5. Übersetzungen überprüfen

### 2. Bestimmte Sprache im Code erzwingen (zum Testen)

`lib/main.dart` vorübergehend ändern, um eine Sprache zu erzwingen:

```dart
return MaterialApp(
  locale: const Locale('es'), // Force Spanish
  localizationsDelegates: const [
    AppLocalizations.delegate,
    // ...
  ],
  supportedLocales: const [
    Locale('en'),
    Locale('es'),
    // ...
  ],
  // ...
);
```

**Denken Sie daran, dies nach dem Testen rückgängig zu machen!**

### 3. Fallback-Verhalten testen

Testen, was passiert, wenn eine Übersetzung fehlt:

1. Einen Schlüssel aus einer nicht-englischen ARB-Datei entfernen
2. Gerät auf diese Sprache einstellen
3. Die App sollte für diese Zeichenkette auf Englisch zurückfallen

### 4. Platzhalterwerte testen

Für Zeichenketten mit Platzhaltern (z. B. `{count}`):

1. Zum Abschnitt „Meine Aquarien" navigieren
2. Mehrere Aquarien erstellen
3. Überprüfen, ob die Anzahl in Ihrer Sprache korrekt angezeigt wird
4. Format prüfen: `"Total: {count}"` sollte `"Total: 3"` anzeigen (oder entsprechendes Äquivalent)

### 5. RTL-Sprachen überprüfen (falls hinzugefügt)

Für Sprachen von rechts nach links wie Arabisch:

1. Gerätesprache auf Arabisch einstellen
2. Überprüfen, ob die Benutzeroberfläche korrekt gespiegelt wird
3. Prüfen, ob der Text rechts ausgerichtet ist
4. Sicherstellen, dass Symbole und Navigation gespiegelt sind

## Was zu testen ist

### Willkommensbildschirm

- [ ] Willkommenstitel
- [ ] Willkommensuntertitel
- [ ] Alle Funktionsnamen (KI-Kompatibilitätstool, KI-Chatbot, etc.)
- [ ] Alle Funktionsbeschreibungen
- [ ] Schaltfläche „Ersten Tank erstellen"

### App-Drawer

- [ ] Titel „Meine Aquarien"
- [ ] Nachricht „Noch keine Aquarien"
- [ ] Alle Menüpunkt-Titel
- [ ] Alle Menüpunkt-Beschreibungen

### Einstellungsbildschirm

- [ ] Titel der Einstellungen
- [ ] Schaltflächentext zum Speichern
- [ ] Erfolgsmeldung nach dem Speichern
- [ ] Fehlermeldungen für fehlende API-Schlüssel
- [ ] Alle Anbieternamen (falls zutreffend)

### Gemeinsame Elemente

- [ ] Ladeanzeigen
- [ ] Fehlermeldungen
- [ ] Erfolgsmeldungen
- [ ] Schaltflächenbeschriftungen (Speichern, Abbrechen, Löschen, etc.)

## Test-Checkliste

### Für jede Sprache

- [ ] Lokalisierungscode generieren: `flutter gen-l10n`
- [ ] App ausführen: `flutter run`
- [ ] Gerätesprache ändern
- [ ] Alle Bildschirme durchnavigieren
- [ ] Überprüfen, ob der gesamte Text übersetzt ist
- [ ] Sicherstellen, dass kein englischer Text erscheint (außer Fachbegriffen)
- [ ] Überprüfen, ob Text in UI-Elemente passt
- [ ] Überprüfen, ob Platzhalter korrekt funktionieren
- [ ] Testen, ob Sonderzeichen korrekt angezeigt werden
- [ ] Überprüfen, ob Text keine Container überläuft

### Randfälle

- [ ] Sehr lange Übersetzungen (z. B. deutsche Komposita)
- [ ] Sehr kurze Übersetzungen
- [ ] Sonderzeichen (é, ñ, ü, etc.)
- [ ] Tief- und Hochstellung (CO₂)
- [ ] Zahlen und Platzhalter

## Build-Tests

### Debug-Build

```bash
flutter build apk --debug
# or
flutter build ios --debug
```

Überprüfen, ob Übersetzungen in der gebauten App funktionieren.

### Release-Build

```bash
flutter build apk --release
# or
flutter build ios --release
```

Sicherstellen, dass keine Übersetzungsdaten im Release-Modus entfernt werden.

## Validierungstools

### 1. ARB-Dateivalidierung

JSON-Syntax validieren:

```bash
# Install jq if not already installed
# macOS: brew install jq
# Ubuntu: sudo apt-get install jq

# Validate ARB files
jq empty lib/l10n/app_en.arb
jq empty lib/l10n/app_es.arb
jq empty lib/l10n/app_fr.arb
jq empty lib/l10n/app_de.arb
```

### 2. Fehlende Übersetzungen prüfen

Schlüsselanzahlen vergleichen:

```bash
# Count keys in English (template)
grep -c '"[a-zA-Z]' lib/l10n/app_en.arb

# Count keys in other languages
grep -c '"[a-zA-Z]' lib/l10n/app_es.arb
grep -c '"[a-zA-Z]' lib/l10n/app_fr.arb
grep -c '"[a-zA-Z]' lib/l10n/app_de.arb
```

Alle sollten übereinstimmen!

### 3. Skript zum Auffinden fehlender Schlüssel

`scripts/check_translations.sh` erstellen:

```bash
#!/bin/bash

TEMPLATE="lib/l10n/app_en.arb"
TRANSLATIONS=(lib/l10n/app_*.arb)

for TRANS in "${TRANSLATIONS[@]}"; do
  if [ "$TRANS" != "$TEMPLATE" ]; then
    echo "Checking $TRANS..."
    TEMPLATE_KEYS=$(jq -r 'keys[]' "$TEMPLATE" | grep -v "^@")
    TRANS_KEYS=$(jq -r 'keys[]' "$TRANS" | grep -v "^@")
    
    echo "$TEMPLATE_KEYS" | while read key; do
      if ! echo "$TRANS_KEYS" | grep -q "^$key$"; then
        echo "  Missing: $key"
      fi
    done
  fi
done
```

Ausführen:

```bash
chmod +x scripts/check_translations.sh
./scripts/check_translations.sh
```

## Häufige Probleme und Lösungen

### Problem: AppLocalizations not found

**Lösung:** `flutter gen-l10n` ausführen und IDE neu starten

### Problem: Übersetzung wird nicht angezeigt

**Lösung:**

1. ARB-Dateisyntax prüfen
2. Schlüssel exakt überprüfen (Groß-/Kleinschreibung beachten)
3. `flutter gen-l10n` ausführen
4. App Hot-Restart durchführen (kein Hot-Reload)

### Problem: Platzhalter funktioniert nicht

**Lösung:**

1. Platzhalter-Syntax überprüfen: `{variableName}`
2. Prüfen, ob ARB-Datei einen Platzhalter-Abschnitt hat
3. Sicherstellen, dass der Code den richtigen Parameter übergibt

### Problem: Textüberlauf

**Lösung:**

1. `Flexible`- oder `Expanded`-Widgets verwenden
2. Textumbruch aktivieren: `overflow: TextOverflow.ellipsis`
3. Abkürzungen in der Übersetzung in Betracht ziehen

### Problem: Sonderzeichen werden als Kästchen angezeigt

**Lösung:**

1. Sicherstellen, dass die Schriftart den Zeichensatz unterstützt
2. Schriftkonfiguration in `pubspec.yaml` prüfen
3. Dateikodierung als UTF-8 überprüfen

## Automatisiertes Testen

### Widget-Tests

```dart
testWidgets('Welcome screen shows translated text', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const WelcomeScreen(),
    ),
  );
  
  expect(find.text('Bienvenido'), findsOneWidget);
});
```

### Integrationstests

```dart
testWidgets('Language switches correctly', (tester) async {
  // Test language switching functionality
});
```

## Performance-Tests

Sicherstellen, dass die Lokalisierung die Leistung nicht beeinträchtigt:

1. App im Profilmodus ausführen: `flutter run --profile`
2. Prüfen, ob Bildwiederholraten konsistent bleiben
3. Speichernutzung überwachen
4. Auf Geräten mit geringer Leistung testen

## Barrierefreiheitstests

Sicherstellen, dass Übersetzungen barrierefrei sind:

- [ ] Screenreader funktionieren korrekt
- [ ] Textskalierung funktioniert
- [ ] Hochkontrastmodus funktioniert
- [ ] Semantische Labels sind bei Bedarf lokalisiert

## Dokumentation

Testergebnisse dokumentieren:

1. Testbericht für jede Sprache erstellen
2. Gefundene Probleme notieren
3. Lösungsansätze oder erforderliche Korrekturen dokumentieren
4. Diesen Leitfaden mit neuen Erkenntnissen aktualisieren

## Kontinuierliche Integration

Zur CI/CD-Pipeline hinzufügen:

```yaml
# .github/workflows/test.yml
- name: Validate ARB files
  run: |
    for file in lib/l10n/app_*.arb; do
      jq empty "$file" || exit 1
    done

- name: Generate localizations
  run: flutter gen-l10n

- name: Run tests
  run: flutter test
```

## Vor dem Release

- [ ] Alle ARB-Dateien validiert
- [ ] Alle Übersetzungen vollständig
- [ ] Code-Generierung erfolgreich
- [ ] App in allen unterstützten Sprachen getestet
- [ ] Screenshots für jede Sprache erstellt (für Store-Einträge)
- [ ] Übersetzungskredite im Über-Abschnitt aktualisiert
- [ ] Release-Notes erwähnen neue Sprachen

## Feedback sammeln

Nach dem Release:

- Benutzerfeedback zur Übersetzungsqualität überwachen
- Analysen zur Sprachnutzung prüfen
- Issues für gemeldete Übersetzungsprobleme erstellen
- Übersetzungen basierend auf Feedback aktualisieren

## Ressourcen

- [Flutter-Internationalisierungsdokumentation](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [ARB-Dateiformat](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
- [Übersetzungsleitfaden](TRANSLATION_GUIDE.md)
- [Entwicklerleitfaden](LOCALIZATION_DEV_GUIDE.md)

## Hilfe erhalten

Wenn Tests fehlschlagen oder Probleme auftreten:

1. Diesen Leitfaden prüfen
2. Flutter i18n-Dokumentation lesen
3. Bestehende GitHub-Issues durchsuchen
4. Ein neues Issue erstellen mit:
   - Fehlermeldung
   - Reproduktionsschritte
   - ARB-Dateiinhalt (falls relevant)
   - Geräte-/Emulatorinformationen

Viel Spaß beim Testen! 🧪
