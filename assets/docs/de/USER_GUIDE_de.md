# Aquarium AI – Benutzerhandbuch

Willkommen bei **Aquarium AI**! Dieses Handbuch erklärt jedes Werkzeug in der App und
wie Sie es optimal nutzen können.

---

## Inhaltsverzeichnis

1. [Erste Schritte – AI-API-Schlüssel](#erste-schritte--ai-api-schlüssel)
2. [Tankverwaltung](#tankverwaltung)
3. [AI-Kompatibilitäts-Tool](#ai-kompatibilitäts-tool)
4. [AI-Chatbot](#ai-chatbot)
5. [Foto-Analysator](#foto-analysator)
6. [Wasserparameter-Analyse](#wasserparameter-analyse)
7. [Fisch-Info-Suche](#fisch-info-suche)
8. [Automatisierungsskript-Generator](#automatisierungsskript-generator)
9. [AI-Besatz-Assistent](#ai-besatz-assistent)
10. [Aquarium-Rechner](#aquarium-rechner)
11. [Parameter-Logger](#parameter-logger)
12. [Dosierungs-Logger](#dosierungs-logger)
13. [Analyse-Historie](#analyse-historie)
14. [Community](#community)
15. [Einstellungen & Erscheinungsbild](#einstellungen--erscheinungsbild)

---

## Erste Schritte – AI-API-Schlüssel

Die meisten KI-gestützten Tools benötigen einen API-Schlüssel von einem unterstützten
Anbieter.

**Kostenlose Stufe (kein Schlüssel erforderlich):**

Aquarium AI enthält eine begrenzte kostenlose Stufe, die von einem integrierten
Entwicklerschlüssel betrieben wird. Diese Stufe unterstützt eine kleine Anzahl von
Anfragen pro Tag mit einem kürzeren Chat-Verlaufsfenster. Sie kann jederzeit reduziert
oder deaktiviert werden.

**Eigenen Schlüssel verwenden (empfohlen):**

Für unbegrenzten Zugriff fügen Sie Ihren eigenen API-Schlüssel unter
**Einstellungen → AI-API-Schlüssel** hinzu. Unterstützte Anbieter:

| Anbieter | Wo man einen Schlüssel bekommt |
| -------- | ------------------------------ |
| **Groq** (Standard) | [console.groq.com](https://console.groq.com) |
| **Google Gemini** | [aistudio.google.com](https://aistudio.google.com) |
| **OpenAI (ChatGPT)** | [platform.openai.com](https://platform.openai.com) |

Sie können den aktiven KI-Anbieter jederzeit unter **Einstellungen → AI-Anbieter**
wechseln.

---

## Tankverwaltung

**Route:** Hauptmenü → *Tankverwaltung*

Die Tankverwaltung ist die zentrale Anlaufstelle für die Verfolgung Ihrer Aquarien.

### Einen Tank erstellen

1. Tippen Sie auf die **+**-Schaltfläche (unten rechts).
2. Geben Sie **Name**, **Typ** (Süßwasser / Meerwasser) und **Volumen** (Gallonen oder
   Liter) ein.
3. Optional: **Beschreibung**, riffverträglich-Flag und ein **Foto** oder **Bannerbild**
   hinzufügen.
4. Tippen Sie auf **Speichern**.

### Tank-Karten

Jede Karte zeigt:

- Tank-Foto / Bannerbild
- Name, Typ und Volumen
- Bewohnerzahl und Harmoniebewertung
- Schnellzugriff-Schaltflächen (Bewohner hinzufügen, Parameter-Log, Dosierungs-Log,
  AI-Analyse)

### Sortieren & Filtern

Verwenden Sie die **Sortier-/Filter**-Schaltfläche (oben rechts), um Tanks nach Name,
Typ, Größe oder Datum zu sortieren und nach Tank-Typ oder Tags zu filtern.

### Tank-Tags

Weisen Sie Tanks farbige **Tags** zur einfachen Gruppierung zu. Tippen Sie auf einen
Tag-Chip, um die Liste zu filtern. Verwalten Sie Ihre globale Tag-Bibliothek unter
**Einstellungen → Arten-Tags**.

### Tank-Details

Tippen Sie auf eine Tank-Karte, um deren Details zu öffnen, in Tabs organisiert:

- **Übersicht** – Tank-Informationen bearbeiten, Harmoniebewertung anzeigen
- **Bewohner** – Fische und andere Bewohner verwalten
- **Parameter** – Wasserparameter-Log und -Diagramme
- **Dosierung** – Behandlungs-/Ergänzungsprotokoll
- **Aktivität** – Aktuelle Ereignisse

### AI-Tools aus einem Tank

Von einer Tank-Karte oder deren Detailansicht können Sie AI-Tools starten, die mit
Ihren Tank-Daten vorgeladen sind:

- **AI-Kompatibilitätsprüfung** – Alle aktuellen Bewohner analysieren
- **Besatzempfehlungen** – AI-Vorschläge für neue Ergänzungen erhalten
- **Fotoanalyse** – Ein Tank-Foto analysieren

### Sicherung & Wiederherstellung

Verwenden Sie **Einstellungen → Sicherung / Wiederherstellung**, um alle Tank-Daten
in eine JSON-Datei zu exportieren und auf einem anderen Gerät zu importieren.

---

## AI-Kompatibilitäts-Tool

**Route:** Hauptmenü → *AI-Kompatibilitäts-Tool*
**Erfordert:** API-Schlüssel oder kostenlose Stufe

Das Kompatibilitäts-Tool ermöglicht es Ihnen, Arten aus einer Datenbank mit über 69
Süß- und Meerwasserfischarten auszuwählen und einen detaillierten AI-Bericht zu
erstellen.

### Verwendung

1. Wählen Sie den Tab **Süßwasser** oder **Meerwasser**.
2. Durchsuchen oder **suchen** Sie die Fischliste. Verwenden Sie den Riffverträglich-Filter
   für Meerwasser-Tanks.
3. **Tippen Sie auf Fischkarten**, um die zu prüfenden Arten auszuwählen (ausgewählte
   Karten zeigen ein Häkchen).
4. Tippen Sie auf **Kompatibilität prüfen**, um den AI-Bericht zu erstellen.

### Den Bericht lesen

Der Bericht enthält:

- **Gesamtkompatibilitätsbewertung** mit Harmoniepunktzahl
- **Artspezifische Pflegehinweise** (pH, Temperatur, Aggressivität)
- **Mögliche Konfliktwarnungen**
- **Empfohlene Tankgröße** für die ausgewählte Gruppe

---

## AI-Chatbot

**Route:** Hauptmenü → *AI-Chatbot*
**Erfordert:** API-Schlüssel oder kostenlose Stufe

Der Chatbot ist ein universeller Aquarium-Assistent. Fragen Sie alles über Fischpflege,
Wasserchemie, Krankheitserkennung, Ausrüstung und mehr.

### Integrierte AI-Tool-Chips

Am oberen Rand des Chat-Bildschirms finden Sie Schnellstart-Chips für spezialisierte
AI-Tools:

- **Foto-Analysator** – Ohne den Chat zu verlassen starten
- **Wasserparameter-Analyse**
- **Fisch-Info**
- **Automatisierungsskript-Generator**

### Chat-Tipps

- Unterhaltungen bleiben jetzt über App-Sitzungen hinweg erhalten.
- Verwenden Sie das Menü **Unterhaltungen** oben rechts, um benannte Unterhaltungen zu
  erstellen.
- Sie können jede Unterhaltung optional einem bestimmten Aquarium zuordnen und später
  im Unterhaltungs-Manager filtern und laden.
- Tippen Sie auf das **Teilen**-Symbol bei einer Antwort, um den Text zu teilen oder
  zu kopieren.
- Erstellen Sie über das Menü eine **neue Unterhaltung**, wenn Sie neu starten möchten.

---

## Foto-Analysator

**Route:** AI-Chatbot → *Foto-Analysator-Chip* oder Hauptmenü → *Foto-Analysator*

**Erfordert:** API-Schlüssel oder kostenlose Stufe (Gemini oder OpenAI für beste
Ergebnisse)

Analysieren Sie Aquariumfotos, um Fische zu identifizieren, Krankheiten zu erkennen,
die Wasserklarheit zu beurteilen und Empfehlungen zu erhalten.

### Verwendung

1. Tippen Sie auf **Aus Galerie wählen** oder **Foto aufnehmen**.
2. (Optional) Fügen Sie eine Notiz hinzu, die beschreibt, wonach Sie suchen (z. B.
   "Ist das Ich?").
3. Tippen Sie auf **Foto analysieren**.
4. Der Ergebnisbildschirm zeigt die Erkenntnisse der KI mit empfohlenen Maßnahmen.

---

## Wasserparameter-Analyse

**Route:** AI-Chatbot → *Wasserparameter-Analyse-Chip*
**Erfordert:** API-Schlüssel oder kostenlose Stufe

Geben Sie Ihre aktuellen Wasserparameter ein und erhalten Sie eine AI-Interpretation
mit gezielten Ratschlägen.

### Eingaben

- **Tank-Typ** (Süßwasser / Meerwasser)
- **pH-Wert**
- **Temperatur** (°F oder °C)
- **Salzgehalt / spezifisches Gewicht** (nur Meerwasser)
- **Zusätzliche Notizen** (Ammoniak, Nitrit, Nitrat, KH usw.)

Die KI markiert Werte außerhalb gesunder Bereiche und schlägt Korrekturmaßnahmen vor.

---

## Fisch-Info-Suche

**Route:** AI-Chatbot → *Fisch-Info-Chip*
**Erfordert:** API-Schlüssel oder kostenlose Stufe

Erhalten Sie ein umfassendes Pflegeblatt für jede Fischart.

### Verwendung

1. Geben Sie einen oder mehrere Artnamen ein (Trivial- oder Wissenschaftsname).
2. Geben Sie optional Ihre Tankgröße für größengerechte Ratschläge ein.
3. Tippen Sie auf **Info abrufen**.

Das Ergebnis enthält:

- Trivial- und Wissenschaftsnamen
- Natürlicher Lebensraum und Herkunft
- Temperatur-, pH- und Wasserhärteanforderungen
- Ernährungs- und Fütterungshinweise
- Kompatible Tankpartner
- Wissenswertes

---

## Automatisierungsskript-Generator

**Route:** AI-Chatbot → *Automatisierungsskript-Chip*
**Erfordert:** API-Schlüssel oder kostenlose Stufe

Erstellen Sie Automatisierungsskripte für Aquariumcontroller (z. B. Apex, GHL, Hydros).

### Verwendung

1. Beschreiben Sie die gewünschte Automatisierung in einfacher Sprache (z. B.
   "Sumpfpumpe um 8 Uhr einschalten, um 22 Uhr ausschalten und Alarm auslösen, wenn
   der pH-Wert unter 7,8 fällt").
2. Tippen Sie auf **Skript generieren**.
3. Das Ergebnis zeigt ein einsatzbereites Skript mit erklärenden Kommentaren.

---

## AI-Besatz-Assistent

**Route:** Hauptmenü → *AI-Besatz-Assistent*
**Erfordert:** API-Schlüssel oder kostenlose Stufe

Erhalten Sie personalisierte Besatzempfehlungen für einen neuen oder bestehenden Tank.

### Verwendung

1. Wählen Sie **Süßwasser** oder **Meerwasser**.
2. Geben Sie Ihre **Tankgröße** ein (optional, verbessert aber die Genauigkeit).
3. (Optional) Wählen Sie Fische, die Sie bereits haben oder haben möchten, mit dem
   **Artenauswähler** aus.
4. Fügen Sie beliebige zusätzliche Notizen hinzu (Biotop-Präferenz, Erfahrungsgrad
   usw.).
5. Tippen Sie auf **Empfehlungen erhalten**.

Der Bericht listet geeignete Arten mit einem kurzen Pflegehinweis für jede auf,
sowie Anleitung zur Besatzdichte.

---

## Aquarium-Rechner

**Route:** Hauptmenü → *Rechner*

Eine Reihe von Offline-Sofortrechner – kein API-Schlüssel erforderlich.

| Rechner | Was er berechnet |
| ------- | ---------------- |
| **Salinität** | Konvertiert zwischen PPT, PSU und spezifischem Gewicht |
| **CO₂** | Schätzt gelöstes CO₂ aus pH und KH |
| **Alkalinität** | Konvertiert zwischen dKH, meq/L und ppm |
| **Temperatur** | Konvertiert zwischen °F und °C |

### Tankvolumen-Rechner

**Route:** Hauptmenü → *Tankvolumen-Rechner*

Berechnen Sie das Wasservolumen von rechteckigen, zylindrischen oder sechseckigen
Tanks anhand innerer Abmessungen.

---

## Parameter-Logger

**Route:** Tank-Details → Registerkarte *Parameter*

(Auch über die Schnellzugriffs-Schaltfläche der Tank-Karte zugänglich)

Verfolgen Sie die Wasserqualität im Laufe der Zeit mit Diagrammen und Protokollen.

### Eine Messung aufzeichnen

1. Tippen Sie auf **+ Parameter hinzufügen**.
2. Wählen Sie den Parametertyp (pH, Ammoniak, Nitrit, Nitrat, Temperatur, Salzgehalt,
   KH usw.) oder geben Sie einen benutzerdefinierten Namen ein.
3. Geben Sie den Wert und die Einheit ein.
4. Tippen Sie auf **Speichern**.

### Diagramme

Tippen Sie auf den **Erweitern**-Pfeil einer Parametergruppe, um ein Zeitreihendiagramm
anzuzeigen. Nützlich zum Erkennen von Trends und zur Validierung der Auswirkungen von
Wasserwechseln.

---

## Dosierungs-Logger

**Route:** Tank-Details → Registerkarte *Dosierung*

(Auch über die Schnellzugriffs-Schaltfläche der Tank-Karte zugänglich)

Führen Sie ein Protokoll über Behandlungen, Ergänzungen und Zusätze.

### Einen Eintrag hinzufügen

1. Tippen Sie auf **+ Dosierungseintrag hinzufügen**.
2. Geben Sie Produktname, Dosiermenge und Einheit ein.
3. Optional Notizen hinzufügen (Grund, Chargennummer usw.).
4. Tippen Sie auf **Speichern**.

Einträge werden nach Produkt gruppiert, um wiederkehrende Behandlungen einfach
nachzuverfolgen.

---

## Analyse-Historie

**Route:** Hauptmenü → *Analyse-Historie*

Jedes AI-Ergebnis (Kompatibilitätsbericht, Besatzempfehlung, Wasserparameter-Analyse,
Fisch-Info, Fotoanalyse) wird hier automatisch gespeichert.

- **Favoriten** durch Tippen auf das Stern-Symbol markieren.
- **Wiedergabe** beliebiger Ergebnisse in voller Länge.
- **Löschen** einzelner Einträge oder der gesamten Historie.

---

## Community

**Route:** Hauptmenü → *Community*

Beiträge anderer Aquarium AI-Benutzer durchsuchen und teilen. Anmelden (anonym oder
mit Google/Facebook), um Beiträge zu verfassen, zu kommentieren und zu reagieren.

### Beitragstypen

- **Allgemein** – Offene Diskussion
- **Frage** – Die Community fragen
- **Präsentation** – Ihren Tank zeigen
- **Tipps** – Wissen teilen

### Anmelden

Tippen Sie auf **Anmelden** am oberen Rand des Community-Bildschirms. Sie können
Google, Facebook oder anonym bleiben verwenden. Anonyme Konten können später unter
**Profil** auf ein benanntes Konto aktualisiert werden.

---

## Einstellungen & Erscheinungsbild

**Route:** Hauptmenü → *Einstellungen*

| Einstellung | Beschreibung |
| ----------- | ------------ |
| **AI-Anbieter** | Zwischen Groq, Gemini und OpenAI wählen |
| **AI-API-Schlüssel** | Persönliche API-Schlüssel speichern |
| **Chat-Verlaufslimit** | Anzahl der vorherigen Nachrichten, die mit jeder Anfrage gesendet werden |
| **Tank-Anzeige** | Fotos, Metriken, Bewohner, Notizen usw. ein-/ausblenden |
| **Sicherung / Wiederherstellung** | Alle Tank-Daten exportieren und importieren |
| **Benachrichtigungen** | Erinnerungen für Wasserwechsel, Fütterung usw. planen |

### Erscheinungsbild

**Route:** Hauptmenü → *Erscheinungsbild* (oder Einstellungen → Erscheinungsbild)

- Aus **15 Farbthemen** wählen, einschließlich Material You (dynamische Farbe aus
  Ihrem Hintergrundbild)
- Benutzerdefinierte Ausgangsfarbe mit dem Farbwähler auswählen
- **Schriftfamilie** wählen (Poppins, Karla, Noto Sans)
- **Hell / Dunkel / System**-Modus umschalten

---

*Für Entwicklerdokumentation, Beitragsleitfäden und Übersetzungshilfe siehe die anderen
Dokumente im Informationsbereich.*
