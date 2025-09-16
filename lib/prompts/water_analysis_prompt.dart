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