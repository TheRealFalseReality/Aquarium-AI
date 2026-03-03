# Übersetzungs-Schnellreferenz

Dies ist eine Schnellreferenz für häufige Übersetzungsszenarien in Aquarium AI.

## Namenskonvention für Dateien

| Sprache | Dateiname | Gebietsschema-Code |
| ------- | --------- | ------------------ |
| Englisch | app_en.arb | en |
| Spanisch | app_es.arb | es |
| Französisch | app_fr.arb | fr |
| Deutsch | app_de.arb | de |
| Japanisch | app_ja.arb | ja |
| Chinesisch (Vereinfacht) | app_zh.arb | zh |
| Portugiesisch | app_pt.arb | pt |
| Italienisch | app_it.arb | it |
| Russisch | app_ru.arb | ru |
| Koreanisch | app_ko.arb | ko |
| Arabisch | app_ar.arb | ar |
| Hindi | app_hi.arb | hi |
| Niederländisch | app_nl.arb | nl |

## Übersetzungsbeispiele

### Einfacher Text

```json
"welcomeTitle": "Welcome"
```

**Deutsch**: `"welcomeTitle": "Willkommen"`
**Japanisch**: `"welcomeTitle": "ようこそ"`
**Spanisch**: `"welcomeTitle": "Bienvenido"`

### Text mit Platzhaltern

```json
"totalTanks": "Total: {count}"
```

**Deutsch**: `"totalTanks": "Gesamt: {count}"`
**Japanisch**: `"totalTanks": "合計: {count}"`
**Spanisch**: `"totalTanks": "Total: {count}"`

**Hinweis**: Behalte `{count}` unverändert – es ist ein Platzhalter!

### Sonderzeichen

```json
"aquariumCalculatorsDescription": "Essential tools for salinity, CO₂, alkalinity and more."
```

Behalte Sonderzeichen wie `CO₂` bei, da es sich um Fachbegriffe handelt.

### Fachbegriffe

Manche Begriffe sollten auf Englisch bleiben oder allgemein anerkannte Übersetzungen verwenden:

- API Key (oft unverändert)
- AI (Artificial Intelligence)
- Modellnamen: Gemini, OpenAI, Groq

### UI-Elemente

```json
"save": "Save",
"cancel": "Cancel",
"delete": "Delete"
```

Diese sollten übersetzt werden und die native Sprache der Benutzeroberfläche der Plattform widerspiegeln.

## Übersetzung testen

### 1. JSON-Validierung

Verwende <https://jsonlint.com/>, um die JSON-Syntax zu validieren.

### 2. Vollständigkeitsprüfung

Vergleiche deine ARB-Datei mit `app_en.arb`:

```bash
# Count keys in English file
grep -c '"[a-zA-Z]' lib/l10n/app_en.arb

# Count keys in your translation
grep -c '"[a-zA-Z]' lib/l10n/app_XX.arb
```

Beide sollten die gleiche Anzahl haben!

### 3. Platzhalter prüfen

Suche nach allen Platzhaltern in deiner Datei:

```bash
grep '{' lib/l10n/app_XX.arb
```

Stelle sicher, dass alle `{count}`, `{name}` usw. vorhanden und unverändert sind.

## Häufige Fehler vermeiden

❌ **Falsch**: Schlüssel übersetzen

```json
"bienvenue": "Bienvenue"  // DON'T translate the key!
```

✅ **Richtig**: Nur Werte übersetzen

```json
"welcomeTitle": "Bienvenue"  // Only the value is translated
```

❌ **Falsch**: Platzhalter entfernen

```json
"totalTanks": "Total: 5"  // Lost the {count} placeholder!
```

✅ **Richtig**: Platzhalter beibehalten

```json
"totalTanks": "Total: {count}"
```

❌ **Falsch**: Ungültiges JSON

```json
{
  "save": "Save"  // Missing comma
  "cancel": "Cancel"
}
```

✅ **Richtig**: Gültiges JSON

```json
{
  "save": "Save",
  "cancel": "Cancel"
}
```

## Hilfe benötigt?

1. Lies die vollständige [Übersetzungsanleitung](TRANSLATION_GUIDE.md)
2. Sieh dir vorhandene Übersetzungen an: [Spanisch](lib/l10n/app_es.arb) oder [Französisch](lib/l10n/app_fr.arb)
3. Verwende die [Vorlagedatei](lib/l10n_template.arb)
4. Öffne ein Issue auf GitHub, wenn du nicht weiterkommst

## Schnellstart-Schritte

1. Kopiere `lib/l10n_template.arb` nach `lib/l10n/app_XX.arb`
2. Ändere `@@locale` auf deinen Sprachcode
3. Ersetze alle "TRANSLATE: "-Texte durch deine Übersetzungen
4. Validiere das JSON unter <https://jsonlint.com/>
5. Aktualisiere `lib/main.dart`, um dein Gebietsschema zu `supportedLocales` hinzuzufügen
6. Reiche einen Pull Request ein!

Vielen Dank für deinen Beitrag! 🌍
