# 🌍 Aquarium AI - Spricht jetzt Ihre Sprache

Aquarium AI ist jetzt übersetzbar! Das bedeutet, dass jeder auf der Welt die App in seiner Muttersprache nutzen kann, und **Sie können helfen** – ganz ohne Programmierkenntnisse!

## 🎯 Schnelle Links

### Für Übersetzer (Kein Programmieren erforderlich!)

- **Starten Sie hier**: [Übersetzungsleitfaden](TRANSLATION_GUIDE.md) – Vollständige Schritt-für-Schritt-Anleitung
- **Schnellstart**: [Kurzreferenz](TRANSLATION_QUICK_REF.md) – Schnelle Tipps und Beispiele
- **Hilfe benötigt?**: [Beitragsleitfaden](CONTRIBUTING.md) – Alle Informationen, die Sie benötigen

### Für Entwickler

- **i18n im Code verwenden**: [Entwicklerleitfaden](LOCALIZATION_DEV_GUIDE.md)
- **Testen**: [Testleitfaden](TESTING_I18N.md)
- **Implementierungsdetails**: [Implementierungszusammenfassung](I18N_IMPLEMENTATION.md)

## 🌐 Aktuell unterstützte Sprachen

| Flagge | Sprache | Status | Mitwirkende benötigt? |
| ------ | ------- | ------ | --------------------- |
| 🇬🇧 | Englisch | ✅ Vollständig | - |
| 🇪🇸 | Spanisch (Español) | ✅ Vollständig | Verbesserungen willkommen |
| 🇫🇷 | Französisch (Français) | ✅ Vollständig | Verbesserungen willkommen |
| 🇩🇪 | Deutsch | ✅ Vollständig | Verbesserungen willkommen |
| 🇵🇹 | Portugiesisch | 🆕 Benötigt | **Ja! Helfen Sie uns!** |
| 🇮🇹 | Italienisch | 🆕 Benötigt | **Ja! Helfen Sie uns!** |
| 🇯🇵 | Japanisch | 🆕 Benötigt | **Ja! Helfen Sie uns!** |
| 🇨🇳 | Chinesisch | 🆕 Benötigt | **Ja! Helfen Sie uns!** |
| 🇷🇺 | Russisch | 🆕 Benötigt | **Ja! Helfen Sie uns!** |
| 🇰🇷 | Koreanisch | 🆕 Benötigt | **Ja! Helfen Sie uns!** |
| 🇳🇱 | Niederländisch | 🆕 Benötigt | **Ja! Helfen Sie uns!** |
| 🇸🇦 | Arabisch | 🆕 Benötigt | **Ja! Helfen Sie uns!** |
| 🇮🇳 | Hindi | 🆕 Benötigt | **Ja! Helfen Sie uns!** |

Möchten Sie Ihre Sprache hinzufügen? **Es ist einfacher als Sie denken!**

## ⚡ Super-Schnellstart (5 Schritte!)

### Für Übersetzer

1. **Vorlage kopieren**

   ```bash
   # Im Projektordner
   cp lib/l10n_template.arb lib/l10n/app_XX.arb
   # (XX durch Ihren Sprachcode ersetzen, z.B. app_pt.arb für Portugiesisch)
   ```

2. **Datei bearbeiten**
   - Ändern Sie `"@@locale": "CHANGE_THIS"` in Ihren Sprachcode (z.B. `"pt"`)
   - Ersetzen Sie alle „TRANSLATE: "-Texte durch Ihre Übersetzungen
   - Lassen Sie `{placeholders}` genau so, wie sie sind

3. **Validieren**

   ```bash
   ./scripts/validate_translations.sh
   ```

4. **main.dart aktualisieren** (oder im PR fragen – wir können helfen!)
   Fügen Sie Ihr Locale zur Liste in `lib/main.dart` hinzu

5. **Einreichen!**
   Erstellen Sie einen Pull Request mit Ihrer Übersetzung

**Das war's!** Sie haben Aquarium AI für Millionen weiterer Menschen zugänglich gemacht! 🎉

### Für Entwickler

1. **Lokalisierung zu einem Widget hinzufügen**

   ```dart
   import 'package:flutter_gen/gen_l10n/app_localizations.dart';

   // In der build-Methode:
   final l10n = AppLocalizations.of(context)!;
   Text(l10n.welcomeTitle) // Zeigt lokalisierten Text an
   ```

2. **Ersteinrichtung** (nach dem Abrufen der Änderungen):

   ```bash
   flutter pub get        # Install dependencies
   flutter gen-l10n       # Generate localization files
   ```

   **Hinweis**: `flutter gen-l10n` wird auch automatisch ausgeführt, wenn Sie `flutter run` oder `flutter build` verwenden.

3. **Neue Zeichenketten hinzufügen**
   - Zu `lib/l10n/app_en.arb` mit Beschreibung hinzufügen
   - `flutter gen-l10n` ausführen
   - Andere Sprachdateien aktualisieren
   - Im Code verwenden!

## 🔧 Fehlerbehebung

### Fehler „Paket nicht gefunden"

Wenn Sie Fehler wie diese sehen:

- `'package:flutter_localizations/flutter_localizations.dart' not found`
- `'package:flutter_gen/gen_l10n/app_localizations.dart' not found`

**Lösung:**

```bash
flutter pub get        # Install dependencies
flutter gen-l10n       # Generate localization files
```

Starten Sie dann Ihre IDE/Ihren Editor neu. Die generierten Dateien befinden sich in `.dart_tool/flutter_gen/gen_l10n/` und werden automatisch erstellt – sie sind nicht in Git enthalten.

## 📊 Was enthalten ist

Diese Implementierung bietet:

### Infrastruktur

- ✅ Offizielles Flutter-i18n-System
- ✅ Typsicherer Zugriff auf Zeichenketten
- ✅ Unterstützung für Platzhalter
- ✅ Professionelles ARB-Dateiformat

### Dokumentation (Wählen Sie, was Sie benötigen)

- **Übersetzer**: [TRANSLATION_GUIDE.md](TRANSLATION_GUIDE.md) + [Kurzreferenz](TRANSLATION_QUICK_REF.md)
- **Entwickler**: [LOCALIZATION_DEV_GUIDE.md](LOCALIZATION_DEV_GUIDE.md)
- **Tester**: [TESTING_I18N.md](TESTING_I18N.md)
- **Alle**: [CONTRIBUTING.md](CONTRIBUTING.md)

### Werkzeuge

- Validierungsskript (überprüft Ihre Übersetzungen automatisch)
- GitHub Actions (automatische Validierung bei PRs)
- Vorlagendatei (Schnellstart für neue Sprachen)

## 🎓 Beispiel: Portugiesisch in 10 Minuten hinzufügen

Lassen Sie uns das Hinzufügen von Portugiesisch durchgehen:

```bash
# 1. Vorlage kopieren
cp lib/l10n_template.arb lib/l10n/app_pt.arb

# 2. app_pt.arb bearbeiten - erste Zeile ändern:
"@@locale": "pt",

# 3. Übersetzen (Beispiel):
"welcomeTitle": "Bem-vindo",
"myTanks": "Meus Aquários",
"settings": "Configurações",
# ... und so weiter

# 4. Validieren
./scripts/validate_translations.sh

# 5. Testen (falls Flutter vorhanden)
flutter gen-l10n
flutter run
# Gerätesprache auf Portugiesisch ändern
```

Fertig! Reichen Sie einen PR ein und werden Sie Mitwirkender! 🌟

## 🤔 FAQ

### F: Ich kann nicht programmieren. Kann ich trotzdem helfen?

**A:** Absolut! Für Übersetzungen sind **keinerlei Programmierkenntnisse** erforderlich. Wenn Sie eine Textdatei bearbeiten können, können Sie übersetzen!

### F: Wie lange dauert es?

**A:** Erstübersetzung: 1–2 Stunden. Aktualisierungen: 5–10 Minuten.

### F: Was, wenn ich einen Fehler mache?

**A:** Kein Problem! Unser Validierungsskript erkennt häufige Fehler. Wir prüfen alle PRs und können bei der Behebung von Problemen helfen.

### F: Ich kenne nur einen Teil der Sprache. Kann ich trotzdem helfen?

**A:** Ja! Teilübersetzungen sind besser als keine. Jemand anderes kann sie später vervollständigen.

### F: Werde ich anerkannt?

**A:** Absolut! Alle Mitwirkenden sind in der Über-Sektion der App und auf GitHub aufgeführt.

### F: Welche Werkzeuge brauche ich?

**A:** Nur einen Texteditor! VS Code, Notepad++, Sublime Text oder sogar Notepad funktionieren einwandfrei.

## 🏆 Warum übersetzen?

### Wirkung

- Helfen Sie **Millionen** von Aquarianern weltweit
- Machen Sie das Hobby in Ihrer Sprache zugänglicher
- Bewahren Sie aquatisches Wissen in mehreren Sprachen

### Anerkennung

- Ihr Name in den App-Danksagungen
- GitHub-Mitwirkenden-Badge
- Anerkennung in den Versionshinweisen
- Bauen Sie Ihr Open-Source-Portfolio auf

### Gemeinschaft

- Treten Sie einer globalen Gemeinschaft von Aquarium-Liebhabern bei
- Helfen Sie, die App für alle zu verbessern
- Lernen Sie, wie Open-Source-Beiträge funktionieren

## 📞 Hilfe erhalten

Nicht weitergekommen? Fragen? Wir sind für Sie da!

1. **Dokumentation lesen**: Die meisten Antworten finden Sie in [TRANSLATION_GUIDE.md](TRANSLATION_GUIDE.md)
2. **Beispiele ansehen**: Schauen Sie sich bestehende Übersetzungen an (Spanisch, Französisch, Deutsch)
3. **Fragen stellen**: Öffnen Sie ein GitHub-Issue mit dem Label „translation"
4. **Diskussionen beitreten**: GitHub-Discussions-Tab

## 🙏 Danke

Jede Übersetzung macht Aquarium AI für alle besser. Egal ob Sie eine einzelne Zeichenkette oder eine ganze Sprache übersetzen – Ihr Beitrag zählt!

**Bereit anzufangen?** Wählen Sie oben eine Anleitung und legen Sie los! 🐠

---

### Verzeichnisstruktur-Referenz

```text
Aquarium-AI/
├── lib/
│   └── l10n/                    # Translation files here!
│       ├── app_en.arb          # English (template)
│       ├── app_es.arb          # Spanish
│       ├── app_fr.arb          # French
│       ├── app_de.arb          # German
│       └── README.md           # L10n guide
├── lib/l10n_template.arb        # Template file (copy to lib/l10n/app_XX.arb)
├── TRANSLATION_GUIDE.md         # START HERE for translators
├── TRANSLATION_QUICK_REF.md     # Quick tips
├── LOCALIZATION_DEV_GUIDE.md    # For developers
├── CONTRIBUTING.md              # General contribution info
└── scripts/
    └── validate_translations.sh # Test your translation
```

---

Mit ❤️ von der Aquarium AI-Gemeinschaft
