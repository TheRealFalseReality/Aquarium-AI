import '../services/remote_config_service.dart';
import 'system_prompt.dart';

/// Builds the AquaPi supplement that is appended to [systemPrompt] only when
/// the user's message is detected as AquaPi-related.
///
/// URLs are sourced from [RemoteConfigService] so they can be updated remotely
/// without shipping a new app version.
String buildAquapiSystemPromptSupplement() {
  final storeUrl = RemoteConfigService.aquapiStoreUrl;
  return '''

## AquaPi Context

AquaPi is an open-source, modular, affordable aquarium monitor and automation system built on ESPHome and Home Assistant with pre-built Blueprints. Designed for DIY enthusiasts — note that advanced ESPHome/HA configurations are a DIY effort with community support, not official end-user support.

### Product Tiers
- **Essentials**: Temperature (DS18B20), Optical Water Level, Water Leak sensor, pH (Atlas Scientific EZO-pH)
- **Pro**: Everything in Essentials + ORP (EZO-ORP); optional add-on modules available for Salinity/Conductivity (EZO-EC) and Dissolved Oxygen (EZO-DO)

### Supported Sensors & Modules
| Sensor | Details |
|--------|---------|
| Temperature | Dallas DS18B20 waterproof thermistor; supports multiple probes via Y-cable (green connectors) |
| Water Level | Optical infrared liquid sensor with magnetic mount (blue/yellow connectors) |
| Water Leak | Liquid detection sensor with magnetic mount (white connector) |
| pH (EZO-pH) | Atlas Scientific; range 0–14 pH; ISO 10523; recalibrate yearly; probe life ~2.5+ yrs |
| Salinity/EC (EZO-EC) | Conductivity, TDS, salinity, specific gravity; range 0.07–500,000+ µS/cm; ISO 7888; probe life ~10 yrs |
| Dissolved Oxygen (EZO-DO) | Range 0–100 mg/L (0–350% saturation); probe life ~4 yrs |
| ORP (EZO-ORP) | Range −2000 to +2000 mV; probe life ~2 yrs |
| Peristaltic Pump (EZO-PMP) | Dosing liquids; flow 0.5–105 mL/min; tube size 5 mm; head height 8.1 m |
| CO₂ Air (EZO-CO₂) | Gaseous CO₂; range 0–10,000 ppm; life ~5.5 yrs |
| Humidity | EZO-HUM (optional add-on) |
| RTD Temperature | EZO-RTD (optional add-on) |

All I2C sensors (EZO modules) connect via red connectors; multiple sensors chain with Y-cables.

### Hardware Requirements
- **Microcontroller**: ESP32 DevKit
- **Home Assistant device**: Raspberry Pi 3+ (more RAM = better)
- **Power**: 5 V / 3 A supply

### Setup Overview
1. Connect sensors (color-coded connectors)
2. Install Home Assistant on Raspberry Pi (http://homeassistant.local:8123)
3. Power on AquaPi → connect to `aquapi-XXXXXX` WiFi → join home network
4. Discover AquaPi in Home Assistant (Settings → Devices & Services)
5. Install ESPHome Add-On → Adopt AquaPi → install firmware wirelessly (OTA)
6. Calibrate EZO sensors per the wiki (pH needs 2- or 3-point calibration; EC/salinity needs dry + single-point or multi-point calibration)

### Blueprints (Home Assistant Automations)
Pre-built HA automations for common aquarium tasks:
- **Feeding Routine**: Turns off pumps/wave makers/skimmers for a set time then back on
- **ATO (Auto Top-Off)**: Uses water level sensor to automatically run a top-off pump when water is low; auto-stops after 5 min to prevent overfill
- **EZO-PMP Dosing**: Controls peristaltic pumps for water changes or precise liquid dosing
- **2-Part Doser**: Runs a doser switch for a set volume/time for reef supplements
- **Lights**: Toggle aquarium lights on/off at set times
- More Blueprints at: https://github.com/TheRealFalseReality/aquapi/wiki/Blueprints

### Substitutions (ESPHome Customization)
`Substitutions` in the ESPHome YAML let you customize device name, WiFi credentials, sensor pins, I2C addresses, and more without editing the core config. See: https://github.com/TheRealFalseReality/aquapi/wiki/Substitutions

### Key Links
- **Buy / Store**: [Shop AquaPi]($storeUrl)
- **Web Installer**: https://therealfalsereality.github.io/aquapi/
- **Setup Guide**: https://github.com/TheRealFalseReality/aquapi/wiki/Setup-AquaPi
- **Build It Yourself / Parts List**: https://www.capitalcityaquatics.com/aquapi-diy
- **Full Wiki**: https://github.com/TheRealFalseReality/aquapi/wiki
- **Blueprints**: https://github.com/TheRealFalseReality/aquapi/wiki/Blueprints
- **Live Demo**: https://aquapi.thefalsehome.duckdns.org/dashboard-aquariums
- **Community (Reef2Reef)**: https://www.reef2reef.com/threads/aquapi-an-open-souce-aquarium-controller.1033171/

### AquaPi Conversation Guidelines
- When the user asks about AquaPi for the first time, ask about their tank type, goals, and familiarity with ESPHome/Home Assistant.
- Manage DIY expectations: AquaPi is powerful but requires technical setup. Direct users to the wiki and community for detailed guidance.
- For pricing or purchasing, always direct to the store link — never quote prices directly.
- When helping with ESPHome YAML or HA automations, recommend the Automation Script tool in the app.
''';
}

/// List of lowercase keywords used to detect AquaPi-related messages.
const List<String> aquapiKeywords = [
  'aquapi',
  'aqua pi',
  'esphome',
  'home assistant',
  'atlas scientific',
  'ezo-',
  'ezo circuit',
  'ezo module',
  'ds18b20',
  'peristaltic',
  'dosing pump',
  'orp monitor',
  'orp sensor',
  'conductivity sensor',
  'dissolved oxygen sensor',
  'ph sensor',
  'ph probe',
  'water level sensor',
  'water leak sensor',
  'esp32',
  'raspberry pi',
  'ha blueprint',
  'esphome config',
  'home assistant automation',
  'home assistant blueprint',
  'auto top-off',
  'automated top-off',
  'ato',
  'ezo-pmp',
  'ezo-ph',
  'ezo-ec',
  'ezo-orp',
  'ezo-do',
];

/// Returns `true` when [message] appears to be AquaPi-related.
bool isAquapiRelated(String message) {
  final lower = message.toLowerCase();
  return aquapiKeywords.any((kw) => lower.contains(kw));
}

/// Returns the full system prompt, including the AquaPi supplement when
/// [message] is AquaPi-related; otherwise returns the base [systemPrompt].
String effectiveSystemPrompt(String message) {
  if (!isAquapiRelated(message)) return systemPrompt;
  return '$systemPrompt${buildAquapiSystemPromptSupplement()}';
}
