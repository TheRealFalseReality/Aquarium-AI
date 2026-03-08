# Änderungsprotokoll

Alle wichtigen Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

## [3.1.03] – 7.3.2026 – UUIDs, hauptsächlich Autorisierungsprüfungen, Facebook-Login-Unterstützung

### Geändert

### ***Bitte beachten Sie:***
- **Möglicherweise müssen Sie Ihren Speicher zurücksetzen, damit der neue Datensatz geladen werden kann. Ich habe den Fischarten UUIDs hinzugefügt, um in Zukunft bessere Änderungen zu ermöglichen.**
- Der Rest besteht hauptsächlich aus Backend-Updates.

**Vollständiges Änderungsprotokoll**: https://github.com/TheRealFalseReality/Aquarium-AI/compare/v3.1.00...v3.1.03

## [3.1.00] - 2026-3-3 – Vorteile, Community- und Profilfunktionen

### Hinzugefügt

- **Benutzerprofilbereich mit Social-Auth hinzugefügt**
- **Gründer-Aquarist-Stufe, modernes Tank-Showcase-Heldenbild, Gründer-Vorteils-System, Community-Post-Korrekturen**
- Vom Benutzer wählbare Schriftfamilien im Erscheinungsbild-Bildschirm
- Riffbecken-Untertyp für Meerwasserbecken mit Filterunterstützung hinzugefügt
- Fischdaten-Sortierung und Riffverträglichkeits-Klassifizierung hinzugefügt
- Globale TankTag-Registrierung mit expliziter Sicherungs-/Wiederherstellungsunterstützung hinzugefügt
- Einzeltank-Teilen/Importieren-Funktion hinzugefügt
- Willkommensbildschirm: 2-Spalten-Raster mit Listen/Raster-Umschalter + Tank-Verwaltungsraster/Mosaik-Modus und Karten-Anpassung
- Haupt-Tank-Bannerfoto zum Tank-Details-Bildschirm hinzugefügt
- Dauerhafte Ausblendung des Willkommensbildschirm-Headers ermöglicht

### Geändert

- Chatbot-Vorschlagschips lokalisiert, KI-Antwortsprachen-Einstellung hinzugefügt
- KI-Kompatibilität, Rechner, Info, Informations- und KI-Anbieter-Einstellungsbildschirme lokalisiert
- Hartcodierte Zeichenketten in Einstellungen, Seitenleiste, Willkommensbildschirm, AquaPi-Promo-Dialog, Verlaufsbildschirm und mehr lokalisiert

**Vollständiges Änderungsprotokoll**: <https://github.com/TheRealFalseReality/Aquarium-AI/compare/v3.0.10...v3.1.00>

## [3.0.10] - 2026-2-27 – Visuelle Updates, Stocking-Tool-Korrekturen

### Hinzugefügt

- Visuellen Kontrast für Schaltflächen und Chips in der gesamten App verbessert
- FlexColorScheme-Themes, AppColorTheme-Palettenauswahl, Erscheinungsbild-Bildschirm und
  benutzerdefinierter Farbwähler hinzugefügt

### Behoben

- Fehler behoben, bei dem das Arten-Popup keine gebräuchlichen Namen widerspiegelte
- Rücknavigations-Fehler im AI-Stocking-Tool behoben, Artauswahl-UX verbessert und
  Tankgröße optional gemacht

**Vollständiges Änderungsprotokoll**:
<https://github.com/TheRealFalseReality/Aquarium-AI/compare/v3.0.03...v3.0.10>

## [3.0.03] - 2026-2-24 – Große Updates

### Hinzugefügt

- **Entwickler-Groq-API-Schlüssel-Fallback mit Ratenbegrenzung; Standardanbieter → Groq**
  - **Kostenlose In-App-AI-Funktionen aktiviert!!** Diese sind begrenzt und können
    jederzeit deaktiviert werden. Standardmäßig wird Groq verwendet – nicht so leistungsfähig
    wie Gemini, aber funktionsfähig.
- **Kauf mir einen Kaffee!** Option zum Entfernen von Anzeigen für **0,99 USD** hinzugefügt.
  Dies sind die *„Gründer-Vorteile"* für Unterstützer der Entwicklung.
- **AI-Fischinformations-Tool hinzugefügt**, dedizierter Ergebnisbildschirm und prominente
  Tool-Chips in der AI-Chatbot-Karte
- Natives Share-Sheet für alle AI-Analyseergebnisse hinzugefügt
- Themenfarben in der gesamten App-UI mit Abschnittsgliederung hinzugefügt
- In-App-Änderungsprotokoll in Einstellungen und Informationsbildschirmen hinzugefügt
- AI-Analysehistorie hinzugefügt: persistentes Protokoll mit Favoriten und
  vollständiger Bericht-Wiedergabe
- Granularen Artauswahldialog zum Kompatibilitäts-Tool hinzugefügt
- Arten-Tags zu Tank-Bewohnern hinzugefügt

### Geändert

- Tank-Details und Erstellungsbildschirme auf Registerkartennavigation umgestellt
- Willkommen-Bildschirm-Kartenbeschreibungen mit spezifischen Funktionsdetails verbessert
- Bewohner-Überlagerung überarbeitet: einklappbarer Fischauswahl, oberer Abstand,
  intelligenter Namenschutz
- AI-Token-Verbrauch bei allen Anbietern reduziert
- Unbegrenztes Token-Wachstum in allen Chat-Anbietern mit konfigurierbarem Verlaufslimit
  behoben
- Robuste KI-Fehlerbehandlung: moderner Dialog, API-Schlüssel-Verknüpfungen und
  Rollback bei Ratenlimit-Fehler

### Entfernt

- „Benutzerdefinierte Namen einbeziehen" aus AI-Bericht-Dialogen entfernt

**Vollständiges Änderungsprotokoll**:
<https://github.com/TheRealFalseReality/Aquarium-AI/compare/v2.1.04...v3.0.03>

## [Unveröffentlicht]

### Noch hinzuzufügen

- Fisch-, Ausrüstungs- und pflanzenspezifische Details mit Bildern
- Bessere und modernere Parameter- und Dosier-UX/UI
- Detaillierte Metriken pro Tank mit benutzerdefinierten Metriken (letzter Wasserwechsel,
  Fischanzahl, Algenstand?)
- Bestückungsleitfäden pro Tank
- Benachrichtigungen und Ereignisprotokoll in Kalenderansicht
- Ausgaben oder GuV
- Tanks mit Freunden teilen und importieren
- Explore-Feed
- [**Mehr vorschlagen!**](https://github.com/TheRealFalseReality/Aquarium-AI/issues)
  Funktion anfragen oder Fehler melden

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
und dieses Projekt hält sich an [Semantic Versioning](https://semver.org/spec/v2.0.0.html).