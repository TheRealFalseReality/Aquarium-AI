import '../services/remote_config_service.dart';

String buildWaterAnalysisPrompt({
  required String tankType,
  required String ph,
  required String temp,
  required String salinity,
  required String additionalInfo,
  required String tempUnit,
  required String salinityUnit,
}) {
  final aquapiStoreUrl = RemoteConfigService.aquapiStoreUrl;
  return '''
    Act as an aquarium expert. Analyze the following water parameters for a $tankType aquarium:
    ${ph.isNotEmpty ? '- pH: $ph' : ''}
    - Temperature: "$temp°$tempUnit"
    ${salinity.isNotEmpty ? '- Salinity: $salinity ${salinityUnit == 'ppt' ? 'ppt' : 'Specific Gravity (SG)'}' : ''}
    ${additionalInfo.isNotEmpty ? '- Additional Information: $additionalInfo' : ''}

    IMPORTANT RULES:
    - Only evaluate parameters that are explicitly listed above. Do NOT infer, assume, or flag any parameter that was not provided.
    - If a parameter such as salinity is absent, it was intentionally omitted and must not appear in the output or be treated as an issue.
    - The overall summary status must reflect only the parameters that were actually provided.
    - For the 'value' field of the temperature parameter, use the original user-provided value '$temp°$tempUnit'. For all other numeric parameters, return the value as a string.
    - The status for each parameter and the overall summary MUST be one of "Good", "Needs Attention", or "Bad".
    - The 'howAquaPiHelps' section should mention how AquaPi can monitor these specific parameters and conclude with: [Shop AquaPi]($aquapiStoreUrl).

    Healthy parameter ranges for reference:
    - Temperature: 22–28°C (72–82°F) for most fish; 24–28°C tropical; 20–24°C coldwater; 24–26°C reef
    - pH: 6.5–8.0 freshwater; 8.0–8.4 saltwater/marine
    - Salinity: 30–35 ppt for saltwater; 1.020–1.025 SG
    - Dissolved Oxygen: 6+ mg/L or 85%+ saturation (>120% saturation / 12+ mg/L can cause gas bubble disease)
    - ORP: 250–400 mV freshwater; 300–400 mV saltwater

    Return a single JSON object with this exact structure (include only parameters that were provided):
    {
      "summary": { "status": "Good" | "Needs Attention" | "Bad", "title": "...", "message": "..." },
      "parameters": [
        { "name": "Temperature", "value": "$temp°$tempUnit", "idealRange": "...", "status": "Good" | "Needs Attention" | "Bad", "advice": "..." }
        // include one entry per provided parameter only
      ],
      "howAquaPiHelps": "..."
    }
    ''';
}
