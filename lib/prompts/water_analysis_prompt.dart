String buildWaterAnalysisPrompt({
  required String tankType,
  required String ph,
  required String temp,
  required String salinity,
  required String additionalInfo,
  required String tempUnit,
  required String salinityUnit,
}) {
  return '''
    Act as an aquarium expert. Analyze the following water parameters for a $tankType aquarium:
    ${ph.isNotEmpty ? '- pH: $ph' : ''}
    - Temperature: "$temp°$tempUnit"
    ${salinity.isNotEmpty ? '- Salinity: $salinity ${salinityUnit == 'ppt' ? 'ppt' : 'Specific Gravity (SG)'}' : ''}
    ${additionalInfo.isNotEmpty ? '- Additional Information: $additionalInfo' : ''}
    Provide a detailed but easy-to-understand analysis. Respond with a JSON object.
    IMPORTANT: For the 'value' field of the temperature parameter, you MUST use the original user-provided value which is '$temp°$tempUnit'. For all other parameters, if their value is numeric, please return it as a string in the JSON.
    The status for each parameter and the overall summary MUST be one of "Good", "Needs Attention", or "Bad".
    The 'howAquaPiHelps' section should conclude with a subtle link to our store: [Shop AquaPi](https://www.capitalcityaquatics.com/store).

    When considering the parameters, use the following guidelines for healthy ranges:
    - Temperature: 22-28°C (72-82°F) for most fish, 24-28°C (76-82°F) acceptable for tropical fish, 20-24°C (68-75°F) for coldwater fish, 24-26°C (75-79°F) for reef tanks
    - Water Level: 80%+ if percentage, otherwise ensure within acceptable range for tank size
    - pH: 6.5-8.0 for freshwater, 8.0-8.4 for saltwater/marine
    - Salinity: 30-35 ppt/psu for saltwater, 1.020-1.025 SG or 46.25-53.06 mS/cm for saltwater specific gravity/conductivity
    - Dissolved Oxygen: 6+ mg/L, 85%+ saturation, 7+ ppm. But Higher levels (up to 120% saturation or 12+ mg/L) can lead to gas bubble disease
    - ORP: 250-400 mV for freshwater, 300-400 mV for saltwater/marine
        The JSON structure must be:
    {
      "summary": { "status": "Good" | "Needs Attention" | "Bad", "title": "...", "message": "..." },
      "parameters": [
        { "name": "Temperature", "value": "$temp°$tempUnit", "idealRange": "...", "status": "Good" | "Needs Attention" | "Bad", "advice": "..." }
        // ... other parameters if provided
      ],
      "howAquaPiHelps": "..."
    }
    ''';
}
