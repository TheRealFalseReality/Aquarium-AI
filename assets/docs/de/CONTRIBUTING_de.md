# Zu Aquarium AI beitragen

Vielen Dank für Ihr Interesse, zu Aquarium AI beizutragen! Dieses Dokument enthält Richtlinien für Beiträge zum Projekt.

## Möglichkeiten zur Mitwirkung

### 🌍 Übersetzungen (Kein Programmieren erforderlich!)

Eine der einfachsten und wirkungsvollsten Möglichkeiten, beizutragen, ist die Übersetzung der App in Ihre Sprache. Weitere Informationen finden Sie in unserem [Übersetzungsleitfaden](TRANSLATION_GUIDE.md).

**Schnellstart für Übersetzungen:**

1. Lesen Sie die [Übersetzungs-Kurzreferenz](TRANSLATION_QUICK_REF.md)
2. Kopieren Sie die [Vorlagendatei](lib/l10n_template.arb)
3. Übersetzen Sie die Zeichenketten in Ihre Sprache
4. Reichen Sie einen Pull Request ein oder öffnen Sie ein Issue mit Ihrer Übersetzung

### 🐛 Fehlermeldungen

Einen Fehler gefunden? Helfen Sie uns, ihn zu beheben:

1. Prüfen Sie, ob der Fehler bereits in den [Issues](https://github.com/TheRealFalseReality/Aquarium-AI/issues) gemeldet wurde
2. Falls nicht, erstellen Sie ein neues Issue mit:
   - Klarer Beschreibung des Fehlers
   - Schritten zur Reproduktion
   - Erwartetem vs. tatsächlichem Verhalten
   - Screenshots, falls zutreffend
   - Gerät-/Plattforminformationen

### 💡 Funktionswünsche

Haben Sie eine Idee für eine neue Funktion?

1. Prüfen Sie [bestehende Funktionswünsche](https://github.com/TheRealFalseReality/Aquarium-AI/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
2. Falls neu, erstellen Sie ein Issue mit folgenden Angaben:
   - Das Problem, das Ihre Funktion lösen würde
   - Wie Sie sich die Funktion vorstellen
   - Beispiele aus anderen Apps

### 💻 Code-Beiträge

Möchten Sie Code beisteuern? Großartig!

**Bevor Sie beginnen:**

1. Prüfen Sie die [offenen Issues](https://github.com/TheRealFalseReality/Aquarium-AI/issues)
2. Kommentieren Sie das Issue, an dem Sie arbeiten möchten
3. Warten Sie auf die Genehmigung, um doppelte Arbeit zu vermeiden

**Entwicklungsumgebung einrichten:**

1. Forken Sie das Repository
2. Klonen Sie Ihren Fork: `git clone https://github.com/YOUR_USERNAME/Aquarium-AI.git`
3. Erstellen Sie einen Branch: `git checkout -b feature/your-feature-name`
4. Nehmen Sie Ihre Änderungen vor
5. Testen Sie Ihre Änderungen gründlich
6. Committen Sie mit klaren Nachrichten: `git commit -m "Add feature: description"`
7. Pushen Sie zu Ihrem Fork: `git push origin feature/your-feature-name`
8. Erstellen Sie einen Pull Request

**Code-Richtlinien:**

- Halten Sie sich an den vorhandenen Code-Stil
- Schreiben Sie klare, beschreibende Commit-Nachrichten
- Fügen Sie Kommentare für komplexe Logik hinzu
- Aktualisieren Sie die Dokumentation bei Bedarf
- Testen Sie Ihre Änderungen auf möglichst vielen Plattformen

### 📖 Dokumentation

Helfen Sie uns, unsere Dokumentation zu verbessern:

- Tippfehler oder unklare Anweisungen korrigieren
- Beispiele hinzufügen
- Dokumentation übersetzen
- Anleitungen oder Tutorials schreiben

## Pull-Request-Prozess

1. **Dokumentation aktualisieren**: Wenn Ihre Änderung benutzerseitige Funktionen betrifft, aktualisieren Sie die relevanten Dokumente
2. **Konventionen befolgen**: Halten Sie sich an den vorhandenen Code-Stil und die Struktur
3. **Gründlich testen**: Stellen Sie sicher, dass Ihre Änderungen wie erwartet funktionieren
4. **Kleine PRs**: Halten Sie Pull Requests auf eine einzelne Funktion/Korrektur fokussiert
5. **Änderungen beschreiben**: Verfassen Sie eine klare Beschreibung des Was und Warum

## Übersetzungsspezifische Richtlinien

### Dateistruktur

```text
├── app_en.arb    (English - template, always complete)
├── app_es.arb    (Spanish)
├── app_fr.arb    (French)
├── app_de.arb    (German)
└── app_XX.arb    (Your language)
```

### Eine neue Sprache hinzufügen

1. Erstellen Sie `lib/l10n/app_XX.arb` (XX = Sprachcode)
2. Übersetzen Sie alle Zeichenketten aus `app_en.arb`
3. Aktualisieren Sie `lib/main.dart`:

   ```dart
   supportedLocales: const [
     Locale('en'),
     Locale('XX'), // Add your language here
   ],
   ```

4. Testen Sie durch das Ändern Ihrer Gerätesprache
5. Reichen Sie einen PR ein

### Bestehende Übersetzungen aktualisieren

1. Prüfen Sie `app_en.arb` auf neue Zeichenketten
2. Fügen Sie fehlende Übersetzungen in Ihre Sprachdatei ein
3. Reichen Sie einen PR mit den Aktualisierungen ein

## Community-Richtlinien

- **Respektvoll sein**: Behandeln Sie jeden mit Respekt und Freundlichkeit
- **Geduldig sein**: Denken Sie daran, dass alle lernen
- **Hilfsbereit sein**: Helfen Sie anderen, wenn Sie können
- **Beim Thema bleiben**: Halten Sie Diskussionen auf Aquarium AI fokussiert

## Fragen?

- **Allgemeine Fragen**: Öffnen Sie eine [Diskussion](https://github.com/TheRealFalseReality/Aquarium-AI/discussions)
- **Fehlermeldungen**: Öffnen Sie ein [Issue](https://github.com/TheRealFalseReality/Aquarium-AI/issues)
- **Übersetzungshilfe**: Siehe [Übersetzungsleitfaden](TRANSLATION_GUIDE.md)

## Anerkennung

Alle Mitwirkenden werden anerkannt in:

- Der Über-Sektion der App
- GitHub-Mitwirkendenseite
- Versionsmitteilungen (für bedeutende Beiträge)

## Lizenz

Durch Ihren Beitrag stimmen Sie zu, dass Ihre Beiträge unter der gleichen Lizenz wie das Projekt (MIT-Lizenz) lizenziert werden.

## Zum ersten Mal dabei?

Willkommen! Hier sind einige gute erste Issues:

- Übersetzung in eine neue Sprache
- Tippfehler in der Dokumentation beheben
- Beispiele zu Anleitungen hinzufügen
- Issues mit dem Label „good first issue"

Vielen Dank, dass Sie Aquarium AI für alle besser machen! 🐠
