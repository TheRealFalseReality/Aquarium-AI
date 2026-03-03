# Lokalisierungs-Verwendungshandbuch für Entwickler

Dieses Handbuch erklärt, wie das Lokalisierungssystem in Aquarium AI für Entwickler verwendet wird, die an der Codebasis arbeiten.

## Einrichtung

Nach dem Pullen der i18n-Änderungen müssen Sie Folgendes tun:

1. **Abhängigkeiten installieren**:

   ```bash
   flutter pub get
   ```

2. **Lokalisierungsdateien generieren**:

   ```bash
   flutter gen-l10n
   ```

   Dadurch wird der Dart-Code in `.dart_tool/flutter_gen/gen_l10n/` generiert.

   **Hinweis**: Dieser Schritt wird auch automatisch ausgeführt, wenn Sie `flutter run` oder `flutter build` ausführen.

3. **Generierte Dateien überprüfen**:
   Die folgenden Dateien sollten generiert werden:
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations.dart`
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations_en.dart`
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations_es.dart`
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations_fr.dart`
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations_de.dart`

## Schnellstart

### Auf Übersetzungen in Widgets zugreifen

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Text(l10n.welcomeTitle);
  }
}
```

### Häufige Muster

#### 1. Einfacher Text

**Vorher:**

```dart
Text('Welcome')
```

**Nachher:**

```dart
Text(AppLocalizations.of(context)!.welcomeTitle)
```

#### 2. Mit Platzhaltern

**Vorher:**

```dart
Text('Total: $count')
```

**Nachher (in ARB-Datei):**

```json
"totalTanks": "Total: {count}",
"@totalTanks": {
  "description": "Total number of tanks",
  "placeholders": {
    "count": {
      "type": "int"
    }
  }
}
```

**Nachher (im Code):**

```dart
Text(AppLocalizations.of(context)!.totalTanks(count))
```

#### 3. In AppBar

**Vorher:**

```dart
AppBar(
  title: Text('Settings'),
)
```

**Nachher:**

```dart
AppBar(
  title: Text(AppLocalizations.of(context)!.settings),
)
```

#### 4. In Dialogen

**Vorher:**

```dart
AlertDialog(
  title: Text('Error'),
  content: Text('Something went wrong'),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('Close'),
    ),
  ],
)
```

**Nachher:**

```dart
final l10n = AppLocalizations.of(context)!;

AlertDialog(
  title: Text(l10n.error),
  content: Text('Something went wrong'), // Add to ARB if needed
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(l10n.close),
    ),
  ],
)
```

#### 5. In ListView/ListTile

**Vorher:**

```dart
ListTile(
  title: Text('My Tanks'),
  subtitle: Text('Manage your aquariums'),
)
```

**Nachher:**

```dart
final l10n = AppLocalizations.of(context)!;

ListTile(
  title: Text(l10n.myTanks),
  subtitle: Text('Manage your aquariums'), // Add to ARB if needed
)
```

## Neue Zeichenketten hinzufügen

### Schritt 1: Zu app_en.arb hinzufügen

```json
{
  "newStringKey": "English Text",
  "@newStringKey": {
    "description": "Description of what this string is for"
  }
}
```

### Schritt 2: Code-Generierung ausführen

```bash
flutter gen-l10n
```

Dadurch wird der Dart-Code in `.dart_tool/flutter_gen/gen_l10n/` generiert.

### Schritt 3: Im Code verwenden

```dart
Text(AppLocalizations.of(context)!.newStringKey)
```

### Schritt 4: Andere Sprachen aktualisieren

Übersetzungen zu `app_es.arb`, `app_fr.arb` usw. hinzufügen.

## Arbeiten mit Pluralformen

Für Zeichenketten, die sich je nach Anzahl ändern:

**In app_en.arb:**

```json
{
  "tankCount": "{count, plural, =0{No tanks} =1{1 tank} other{{count} tanks}}",
  "@tankCount": {
    "description": "Number of tanks",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

**Im Code:**

```dart
Text(AppLocalizations.of(context)!.tankCount(tankList.length))
```

## Best Practices

### 1. Alle benutzersichtbaren Zeichenketten extrahieren

Jede Zeichenkette, die Benutzer sehen, sollte in ARB-Dateien stehen:

- ✅ Schaltflächenbeschriftungen
- ✅ Bildschirmtitel
- ✅ Fehlermeldungen
- ✅ Beschreibungen
- ✅ Tooltips
- ❌ Debug-Protokolle
- ❌ Interne Bezeichner
- ❌ API-Endpunkte

### 2. Beschreibende Schlüssel verwenden

**Gut:**

```json
"settingsUpdatedSuccess": "Settings updated successfully!"
```

**Schlecht:**

```json
"msg1": "Settings updated successfully!"
```

### 3. Kontext bereitstellen

Immer `@description` einfügen:

```json
{
  "save": "Save",
  "@save": {
    "description": "Save button label"
  }
}
```

### 4. Null-Sicherheit beachten

Immer den Null-Assertionsoperator `!` beim Zugriff auf AppLocalizations verwenden:

```dart
final l10n = AppLocalizations.of(context)!;
```

Dies ist sicher, da wir `localizationsDelegates` in `main.dart` konfigurieren.

### 5. Hilfsvariable erstellen

Für mehrfache Verwendung im selben Widget:

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  
  return Column(
    children: [
      Text(l10n.welcomeTitle),
      Text(l10n.welcomeSubtitle),
      ElevatedButton(
        onPressed: () {},
        child: Text(l10n.save),
      ),
    ],
  );
}
```

## Übersetzungen testen

### 1. Die App in verschiedenen Spracheinstellungen ausführen

Ändern Sie die Sprache Ihres Geräts/Emulators, um Übersetzungen zu testen.

### 2. Spracheinstellung im Code überschreiben (zum Testen)

```dart
MaterialApp(
  locale: Locale('es'), // Force Spanish
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // ...
)
```

### 3. Auf fehlende Übersetzungen prüfen

Wenn eine Übersetzung fehlt, fällt die App auf Englisch zurück.

## Häufige Probleme

### Problem: „AppLocalizations not found"

**Lösung:** Code-Generierung ausführen:

```bash
flutter gen-l10n
```

### Problem: „l10n.myNewString doesn't exist"

**Lösung:**

1. Sicherstellen, dass der Schlüssel in `app_en.arb` vorhanden ist
2. `flutter gen-l10n` ausführen
3. IDE/Editor neu starten

### Problem: Platzhalter funktioniert nicht

**Lösung:** ARB-Dateisyntax prüfen:

```json
{
  "message": "Hello {name}",
  "@message": {
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

## Migrationsleitfaden

So migrieren Sie vorhandene hartcodierte Zeichenketten:

1. **Hartcodierte Zeichenkette finden:**

   ```dart
   Text('Welcome')
   ```

2. **Zu app_en.arb hinzufügen:**

   ```json
   "welcomeTitle": "Welcome"
   ```

3. **Generierung ausführen:**

   ```bash
   flutter gen-l10n
   ```

4. **Code aktualisieren:**

   ```dart
   Text(AppLocalizations.of(context)!.welcomeTitle)
   ```

5. **Zu anderen Sprachdateien hinzufügen:**

   ```json
   // app_es.arb
   "welcomeTitle": "Bienvenido"
   ```

## Dateistruktur

```text
lib/
│   ├── app_en.arb    (English - template)
│   ├── app_es.arb    (Spanish)
│   ├── app_fr.arb    (French)
│   └── ...
└── main.dart

.dart_tool/
└── flutter_gen/
    └── gen_l10n/
        ├── app_localizations.dart
        ├── app_localizations_en.dart
        ├── app_localizations_es.dart
        └── ...
```

## Ressourcen

- [Flutter-Internationalisierungsleitfaden](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [ARB-Dateiformat](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
- [Unser Übersetzungsleitfaden](TRANSLATION_GUIDE.md) – Für Übersetzer

## Beispiel: Vollständige Widget-Migration

**Vorher:**

```dart
class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome'),
      ),
      body: Column(
        children: [
          Text('Your intelligent assistant'),
          ElevatedButton(
            onPressed: () {},
            child: Text('Get Started'),
          ),
        ],
      ),
    );
  }
}
```

**Nachher:**

```dart
class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.welcomeTitle),
      ),
      body: Column(
        children: [
          Text(l10n.welcomeSubtitle),
          ElevatedButton(
            onPressed: () {},
            child: Text(l10n.getStarted),
          ),
        ],
      ),
    );
  }
}
```

Viel Spaß beim Lokalisieren! 🌍
