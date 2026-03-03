# Übersetzungsanleitung für Aquarium AI

Vielen Dank für dein Interesse an der Übersetzung von Aquarium AI! Diese Anleitung hilft dir dabei, Übersetzungen beizutragen und die App für Nutzer weltweit zugänglich zu machen.

## Übersicht

Aquarium AI verwendet das in Flutter integrierte Internationalisierungssystem (i18n) mit ARB-Dateien (Application Resource Bundle). Jede Sprache hat eine eigene ARB-Datei, die alle übersetzbaren Zeichenketten enthält.

## Erste Schritte

### Voraussetzungen

- Grundlegende Kenntnisse des JSON-Formats
- Vertrautheit mit der Zielsprache
- Ein Texteditor (VS Code, Sublime Text oder ein beliebiger Editor)

### Dateistruktur

Die Übersetzungsdateien befinden sich unter:

```text
lib/l10n/
├── app_en.arb    (English - template)
├── app_es.arb    (Spanish - example)
├── app_fr.arb    (French - example)
└── app_XX.arb    (Your language)
```

## So fügst du eine neue Sprache hinzu

### Schritt 1: ARB-Datei erstellen

1. Kopiere die Datei `app_en.arb`
2. Benenne sie in `app_XX.arb` um, wobei `XX` dein Sprachcode ist (z. B. `app_de.arb` für Deutsch, `app_ja.arb` für Japanisch)
3. Aktualisiere den Wert `@@locale` auf deinen Sprachcode

**Häufige Sprachcodes:**

- `de` - Deutsch
- `ja` - Japanisch
- `zh` - Chinesisch (Vereinfacht)
- `pt` - Portugiesisch
- `it` - Italienisch
- `ru` - Russisch
- `ko` - Koreanisch
- `ar` - Arabisch
- `hi` - Hindi
- `nl` - Niederländisch

Weitere Sprachcodes findest du hier: <https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes>

### Schritt 2: Zeichenketten übersetzen

Übersetze die Werte jeder Zeichenkette (aber NICHT die Schlüssel). Hier ein Beispiel:

**Englisch (app_en.arb):**

```json
{
  "@@locale": "en",
  "welcomeTitle": "Welcome",
  "myTanks": "My Tanks"
}
```

**Deutsch (app_de.arb):**

```json
{
  "@@locale": "de",
  "welcomeTitle": "Willkommen",
  "myTanks": "Meine Aquarien"
}
```

### Schritt 3: Platzhalter behandeln

Einige Zeichenketten enthalten Platzhalter wie `{count}`. Diese Platzhalter müssen unverändert bleiben:

**Englisch:**

```json
"totalTanks": "Total: {count}"
```

**Deutsch:**

```json
"totalTanks": "Gesamt: {count}"
```

### Schritt 4: Sonderzeichen beibehalten

Behalte Sonderzeichen und Formatierungen bei:

- Emojis: 🐠, 🤖, 📷, usw.
- Sonderzeichen: CO₂, ₂, usw.
- HTML-Entities und Escape-Sequenzen

### Schritt 5: main.dart aktualisieren

Nachdem du deine ARB-Datei erstellt hast, füge deine Sprache zur Liste `supportedLocales` in `lib/main.dart` hinzu:

```dart
supportedLocales: const [
  Locale('en'), // English
  Locale('es'), // Spanish
  Locale('fr'), // French
  Locale('de'), // German (your new language)
],
```

## Übersetzungstipps

### 1. Kontext ist wichtig

- Lies die `@description`-Felder in der englischen ARB-Datei für Kontext
- Falls unklar, prüfe, wo die Zeichenkette in der App verwendet wird

### 2. Konsistenz wahren

- Verwende durchgehend einheitliche Terminologie
- Behalte einen professionellen, aber freundlichen Ton bei
- Passe deinen Stil an bestehende Übersetzungen an

### 3. Kulturelle Anpassung

- Passe Redewendungen und Ausdrücke an deine Kultur an
- Berücksichtige regionale Unterschiede in deiner Sprache

### 4. Fachbegriffe

Manche Fachbegriffe sollten auf Englisch belassen oder mit allgemein akzeptierten Übersetzungen verwendet werden:

- API Key
- AI (Artificial Intelligence)
- Modellnamen (Gemini, OpenAI, Groq)
- Tank (Aquarium-Terminologie)

### 5. Längenaspekte

- Versuche, Übersetzungen in etwa gleich lang zu halten wie das Original
- Sehr lange Übersetzungen passen möglicherweise nicht in die Benutzeroberfläche
- Falls nötig, verwende in deiner Sprache gebräuchliche Abkürzungen

## Übersetzung testen

Auch wenn wir nicht erwarten, dass du die App selbst erstellst und testest, kannst du deine Arbeit so überprüfen:

1. **JSON-Syntax prüfen**: Verwende einen JSON-Validator (<https://jsonlint.com/>)
2. **Vollständigkeit prüfen**: Stelle sicher, dass alle Schlüssel aus `app_en.arb` übersetzt sind
3. **Platzhalter prüfen**: Überprüfe, ob Platzhalter wie `{count}` erhalten geblieben sind

## ARB-Dateistruktur – Referenz

Jede ARB-Datei enthält:

1. **Gebietsschema-Kennung:**

   ```json
   "@@locale": "en"
   ```

2. **Übersetzungsschlüssel und -wert:**

   ```json
   "welcomeTitle": "Welcome"
   ```

3. **Metadaten (optional, aus Vorlage):**

   ```json
   "@welcomeTitle": {
     "description": "Title for the welcome screen"
   }
   ```

**Wichtig:** Übersetze nur die Werte (rechte Seite), niemals die Schlüssel (linke Seite).

## Übersetzung einreichen

### Per Pull Request (empfohlen)

1. Forke das Repository
2. Erstelle einen neuen Branch: `git checkout -b translation/your-language`
3. Füge deine ARB-Datei zu `lib/l10n/` hinzu
4. Aktualisiere `lib/main.dart`, um dein Gebietsschema einzufügen
5. Committe deine Änderungen: `git commit -m "Add [Language] translation"`
6. Pushe zu deinem Fork: `git push origin translation/your-language`
7. Erstelle einen Pull Request auf GitHub

### Per Issue

Falls du nicht mit Git vertraut bist:

1. Erstelle ein neues Issue auf GitHub
2. Titel: "Translation: [Your Language]"
3. Hänge deine fertige ARB-Datei an
4. Wir werden sie für dich integrieren!

## Übersetzungs-Checkliste

Überprüfe vor dem Einreichen:

- [ ] ARB-Datei ist korrekt benannt (`app_XX.arb`)
- [ ] `@@locale`-Wert stimmt mit dem Dateinamen überein
- [ ] Alle Zeichenketten aus `app_en.arb` sind enthalten
- [ ] Platzhalter sind erhalten geblieben (z. B. `{count}`)
- [ ] Sonderzeichen sind beibehalten
- [ ] JSON-Syntax ist gültig
- [ ] Sprache ist in `supportedLocales` in `main.dart` hinzugefügt

## Hilfe benötigt?

- **Fragen?** Öffne ein Issue auf GitHub mit dem Label „translation"
- **Unsicher bei einer Zeichenkette?** Frage im Issue nach, bevor du übersetzt
- **Fehler gefunden?** Melde ihn oder reiche eine Korrektur ein

## Beispielsprachen

Sieh dir diese Beispiele als Referenz an:

- Englisch: `lib/l10n/app_en.arb` (Vorlage)
- Spanisch: `lib/l10n/app_es.arb`
- Französisch: `lib/l10n/app_fr.arb`

## Danksagungen

Alle Übersetzer werden im About-Bereich der App und in der README aufgeführt. Vielen Dank, dass du Aquarium AI für mehr Menschen zugänglich machst!

## Sprachabdeckungsstatus

| Sprache | Code | Status | Übersetzer |
| ------- | ---- | ------ | ---------- |
| Englisch | en | ✅ Vollständig | Nativ |
| Spanisch | es | ✅ Vollständig | Community |
| Französisch | fr | ✅ Vollständig | Community |
| Deutsch | de | ✅ Vollständig | Community |
| Japanisch | ja | 🔄 Benötigt | - |
| Chinesisch | zh | 🔄 Benötigt | - |
| Portugiesisch | pt | 🔄 Benötigt | - |

Möchtest du deine Sprache hinzufügen? Folge dieser Anleitung und reiche einen PR ein!

## Erweitert: Weitere Zeichenketten hinzufügen

Da sich die App weiterentwickelt, können neue Zeichenketten zu `app_en.arb` hinzugefügt werden. So aktualisierst du deine Übersetzung:

1. Hole die neuesten Änderungen aus dem Haupt-Repository
2. Prüfe, ob neue Zeichenketten zu `app_en.arb` hinzugefügt wurden
3. Füge Übersetzungen für neue Zeichenketten zu deiner ARB-Datei hinzu
4. Reiche einen Update-PR ein

## Danke

Dein Beitrag hilft Aquariumbegeisterten weltweit, diese App in ihrer Muttersprache zu nutzen. Jede Übersetzung macht einen Unterschied! 🌍🐠
