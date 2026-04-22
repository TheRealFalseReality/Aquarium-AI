# Aquarium AI – User Guide

Welcome to **Aquarium AI**! This guide explains every tool in the app and how to get the most out of it.

---

## Table of Contents

1. [Getting Started – AI API Keys](#getting-started--ai-api-keys)
2. [Tank Management](#tank-management)
3. [AI Compatibility Tool](#ai-compatibility-tool)
4. [AI Chatbot](#ai-chatbot)
5. [Photo Analyzer](#photo-analyzer)
6. [Water Parameter Analysis](#water-parameter-analysis)
7. [Fish Info Lookup](#fish-info-lookup)
8. [Automation Script Generator](#automation-script-generator)
9. [AI Stocking Assistant](#ai-stocking-assistant)
10. [Aquarium Calculators](#aquarium-calculators)
11. [Tank Volume Calculator](#tank-volume-calculator)
12. [Substrate Calculator](#substrate-calculator)
13. [Parameter Logger](#parameter-logger)
14. [Dosing Logger](#dosing-logger)
15. [Analysis History](#analysis-history)
16. [Community](#community)
17. [Settings & Appearance](#settings--appearance)

---

## Getting Started – AI API Keys

Most AI-powered tools require an API key from a supported provider.

**Free tier (no key required):**

Aquarium AI includes a limited free tier powered by a built-in developer key. This tier supports a small number of requests per day with a shorter chat history window. It may be reduced or disabled at any time.

**Bring your own key (recommended):**

For unlimited access, add your own API key in **Settings → AI API Keys**. Supported providers:

| Provider | Where to get a key |
| -------- | ------------------ |
| **Groq** (default) | [console.groq.com](https://console.groq.com) |
| **Google Gemini** | [aistudio.google.com](https://aistudio.google.com) |
| **OpenAI (ChatGPT)** | [platform.openai.com](https://platform.openai.com) |

You can switch the active AI provider at any time in **Settings → AI Provider**.

---

## Tank Management

**Route:** Main menu → *Tank Management*

Tank Management is the central hub for tracking your aquariums.

### Creating a Tank

1. Tap the **+** button (bottom-right).
2. Fill in **Name**, **Type** (Freshwater / Marine), and **Volume** (gallons or litres).
3. Optionally add a **Description**, reef-safe flag, and a **photo** or **banner image**.
4. Tap **Save**.

### Tank Cards

Each card shows:

- Tank photo / banner image
- Name, type, and volume
- Inhabitant count and harmony score
- Quick-action buttons (Add Inhabitant, Parameter Log, Dosing Log, AI Analysis)
- Card menu tools, including **Water Change Volume Calculator** (defaults to 20% and lets you adjust the percentage to see gallons/liters to replace)

### Sorting & Filtering

Use the **sort / filter** button (top-right) to sort tanks by name, type, size, or date, and filter by tank type or tags.

### Tank Tags

Assign coloured **tags** to tanks for easy grouping. Tap a tag chip to filter the list. Manage your global tag library in **Settings → Species Tags**.

### Tank Details

Tap any tank card to open its details, organized into tabs:

- **Overview** – edit tank info, view harmony score
- **Inhabitants** – manage fish and other residents
- **Parameters** – water parameter log and charts
- **Dosing** – treatment / supplement log
- **Activity** – recent events

### AI Tools from a Tank

From a tank card or its detail screen you can launch AI tools pre-loaded with your tank's data:

- **AI Compatibility Check** – analyze all current inhabitants
- **Stocking Recommendations** – get AI suggestions for new additions
- **Photo Analysis** – analyze a tank photo

### Backup & Restore

Use **Settings → Backup / Restore** to export all tank data to a JSON file and import it on another device.

---

## AI Compatibility Tool

**Route:** Main menu → *AI Compatibility Tool*  
**Requires:** API key or free tier

The Compatibility Tool lets you select species from a database of 69+ freshwater and marine species and generate a detailed AI report.

### How to Use

1. Choose **Freshwater** or **Marine** tab.
2. Browse or **search** the fish list. Use the reef-safe filter for marine tanks.
3. **Tap fish cards** to select the species you want to check together (selected cards show a checkmark).
4. Tap **Check Compatibility** to generate the AI report.

### Reading the Report

The report includes:

- **Overall compatibility rating** with a harmony score
- **Per-species care notes** (pH, temperature, aggression)
- **Potential conflict warnings**
- **Recommended tank size** for the selected group

---

## AI Chatbot

**Route:** Main menu → *AI Chatbot*  
**Requires:** API key or free tier

The Chatbot is a general-purpose aquarium assistant. Ask anything about fish care, water chemistry, disease identification, equipment, and more.

### Built-in AI Tool Chips

At the top of the chat screen you will find quick-launch chips for specialized AI tools:

- **Photo Analyzer** – launch without leaving the chat
- **Water Parameter Analysis**
- **Fish Info**
- **Automation Script Generator**

### Chat Tips

- The AI remembers recent messages in the current session (configurable in Settings).
- Tap the **share** icon on any response to share or copy the text.
- Use **clear chat** (top-right menu) to start fresh.

---

## Photo Analyzer

**Route:** AI Chatbot → *Photo Analyzer chip*, or Main menu → *Photo Analyzer*

**Requires:** API key or free tier (Gemini or OpenAI for best results)

Analyze aquarium photos to identify fish, detect diseases, assess water clarity, and get recommendations.

### How to Use

1. Tap **Choose from Gallery** or **Take Photo**.
2. (Optional) Add a note describing what you're looking for (e.g. "Is this ich?").
3. Tap **Analyze Photo**.
4. The result screen shows the AI's findings with suggested actions.

---

## Water Parameter Analysis

**Route:** AI Chatbot → *Water Parameter Analysis chip*  
**Requires:** API key or free tier

Enter your current water parameters and receive an AI interpretation with targeted advice.

### Inputs

- **Tank type** (freshwater / marine)
- **pH**
- **Temperature** (°F or °C)
- **Salinity / Specific Gravity** (marine only)
- **Additional notes** (ammonia, nitrite, nitrate, KH, etc.)

The AI will flag values outside healthy ranges and suggest corrective actions.

---

## Fish Info Lookup

**Route:** AI Chatbot → *Fish Info chip*  
**Requires:** API key or free tier

Get a comprehensive care sheet for any fish species.

### How to Use

1. Enter one or more species names (common or scientific).
2. Optionally enter your tank size for size-appropriate advice.
3. Tap **Get Info**.

The result includes:

- Common and scientific names
- Natural habitat and origin
- Temperature, pH, and water hardness requirements
- Diet and feeding notes
- Compatible tank mates
- Fun facts

---

## Automation Script Generator

**Route:** AI Chatbot → *Automation Script chip*  
**Requires:** API key or free tier

Generate automation scripts for aquarium controllers (e.g. Apex, GHL, Hydros).

### How to Use

1. Describe the automation you need in plain language (e.g. "Turn on sump pump at 8 AM, off at 10 PM, and trigger alarm if pH drops below 7.8").
2. Tap **Generate Script**.
3. The result displays a ready-to-use script with explanatory comments.

---

## AI Stocking Assistant

**Route:** Main menu → *AI Stocking Assistant*  
**Requires:** API key or free tier

Get personalized stocking recommendations for a new or existing tank.

### How to Use

1. Select **Freshwater** or **Marine**.
2. Enter your **tank size** (optional but improves accuracy).
3. (Optional) Select fish you already have or want using the **species picker**.
4. Add any extra notes (biotope preference, experience level, etc.).
5. Tap **Get Recommendations**.

The report lists suitable species with a brief care note for each, plus stocking density guidance.

---

## Aquarium Calculators

**Route:** Main menu → *Calculators*

A set of offline, instant calculators — no API key needed.

| Calculator | What it does |
| ---------- | ------------ |
| **Salinity** | Converts between PPT, PSU, and Specific Gravity |
| **CO₂** | Estimates dissolved CO₂ from pH and KH |
| **Alkalinity** | Converts between dKH, meq/L, and ppm |
| **Temperature** | Converts between °F and °C |

### Tank Volume Calculator

**Route:** Main menu → *Tank Volume Calculator*

Calculate the water volume of rectangular, cylinder, or hexagonal tanks using internal dimensions.

---

## Substrate Calculator

**Route:** Main menu → *Substrate Calculator*

Estimate how much substrate you need based on your tank footprint (length × width) and your preferred bed-depth profile.

### Bed Type Options

| Bed Type | Depth | Best For |
| -------- | ----- | -------- |
| Standard | 1–2 in (2.5–5 cm) | Community fish, general freshwater and saltwater |
| Planted | 2–3 in (5–7.5 cm) | Live plant tanks; gives roots room to anchor |
| Deep Bed | 3–4 in (7.5–10 cm) | Advanced planted tanks, deep-rooting species, anaerobic zones |
| Bare Bottom | 0 in | Quarantine tanks, goldfish, high-waste fish |

### Inputs

- **Tank Volume** – the total water volume of your tank.
- **Units** – choose *Gallons* or *Liters*.
- **Bed Type** – selects the lbs-per-gallon multiplier for the calculation.

### Results

The calculator uses the standard **1–2 lbs per gallon** rule, scaled by bed type.
Two cards are shown:

- **Recommended Amount** – the midpoint of the estimated range (the number to aim for).
  Shows weight in lbs / kg and substrate volume in litres.
- **Estimated Range** – the full minimum–maximum spread for weight and volume.

> **Note:** Results use the standard lbs/gal rule. Actual amount varies by substrate
> type (gravel, sand, aqua-soil, etc.). Always verify against the bag weight before
> purchasing.

### Tips

- Buy **10–15 % extra** to account for settling, decoration displacement, and uneven depth.
- Rinse substrate thoroughly before adding it to the tank to prevent cloudy water.
- For planted tanks, consider a nutrient-rich capping substrate below regular gravel or sand.

---

## Parameter Logger

**Route:** Tank Details → *Parameters* tab

(Also accessible from the tank card quick-action button)

Track water quality over time with charts and logs.

### Logging a Reading

1. Tap **+ Add Parameter**.
2. Select the parameter type (pH, Ammonia, Nitrite, Nitrate, Temperature, Salinity, KH, etc.) or enter a custom name.
3. Enter the value and unit.
4. Tap **Save**.

### Charts

Tap the **expand** arrow on a parameter group to view a time-series chart. Useful for spotting trends and validating the impact of water changes.

---

## Dosing Logger

**Route:** Tank Details → *Dosing* tab

(Also accessible from the tank card quick-action button)

Keep a record of treatments, supplements, and additives.

### Adding an Entry

1. Tap **+ Add Dosing Entry**.
2. Enter the product name, dose amount, and unit.
3. Optionally add notes (reason, batch number, etc.).
4. Tap **Save**.

Entries are grouped by product for easy tracking of recurring treatments.

---

## Analysis History

**Route:** Main menu → *Analysis History*

Every AI result (compatibility report, stocking recommendation, water parameter analysis, fish info, photo analysis) is automatically saved here.

- **Favorite** results by tapping the star icon.
- **Replay** any result to view it in full.
- **Delete** individual entries or clear all history.

---

## Community

**Route:** Main menu → *Community*

Browse and share posts with other Aquarium AI users. Sign in (anonymously or with Google/Facebook) to post, comment, and react.

### Post Types

- **General** – open discussion
- **Question** – ask the community
- **Showcase** – share your tank
- **Tips** – share knowledge

### Signing In

Tap **Sign In** at the top of the Community screen. You can use Google, Facebook, or remain anonymous. Anonymous accounts can be upgraded to a named account later in **Profile**.

---

## Settings & Appearance

**Route:** Main menu → *Settings*

| Setting | Description |
|---------|-------------|

| **AI Provider** | Choose between Groq, Gemini, and OpenAI |
| **AI API Keys** | Store your personal API keys |
| **Chat History Limit** | Number of previous messages sent with each request |
| **Tank Display** | Hide/show photos, metrics, inhabitants, notes, etc. |
| **Backup / Restore** | Export and import all tank data |
| **Notifications** | Schedule reminders for water changes, feeding, etc. |

### Appearance

**Route:** Main menu → *Appearance* (or Settings → Appearance)

- Choose from **15 colour themes** including Material You (dynamic colour from your wallpaper)
- Pick a custom seed colour with the colour picker
- Select a **font family** (Poppins, Karla, Noto Sans)
- Toggle **light / dark / system** mode

---

*For developer documentation, contribution guides, and translation help, see the other documents in the Information section.*
