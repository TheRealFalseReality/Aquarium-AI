String buildFishInfoPrompt({
  required String fishNames,
  String? tankSize,
  String? additionalNotes,
}) {
  String prompt = '''
You are an expert aquarist and marine biologist. The user wants comprehensive information about the following fish: $fishNames.''';

  if (tankSize != null && tankSize.isNotEmpty) {
    prompt += '\nTank size context: $tankSize.';
  }

  if (additionalNotes != null && additionalNotes.isNotEmpty) {
    prompt += '\nAdditional notes: $additionalNotes.';
  }

  prompt += '''

Return a single valid JSON object with the following structure. Do not include any text outside the JSON.

{
  "fish": [
    {
      "commonName": "Common Name",
      "scientificName": "Genus species",
      "originHabitat": "Natural location(s) and habitat description",
      "keyFacts": [
        "Adult size: ...",
        "Lifespan: ...",
        "Diet: ...",
        "Temperament: ...",
        "Swimming level: ..."
      ],
      "funFacts": [
        "Interesting fact 1",
        "Interesting fact 2"
      ],
      "care": {
        "minimumTankSize": "e.g. 20 gallons",
        "waterParameters": "Temperature, pH, and any other relevant ranges",
        "tankSetup": "Substrate, plants, hiding spots, flow, etc.",
        "difficultyLevel": "Beginner / Intermediate / Expert"${tankSize != null && tankSize.isNotEmpty ? ',\n        "tankSizeNote": "Suitability notes for a $tankSize tank"' : ''}
      },
      "compatibleTankMates": ["Species A", "Species B"],
      "incompatibleSpecies": ["Species X", "Species Y"]
    }
  ]
}

If multiple fish names are provided, include one entry per fish in the "fish" array. Be accurate and thorough.
''';

  return prompt;
}

