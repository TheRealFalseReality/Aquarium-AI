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

Please provide a detailed, well-formatted Markdown response covering the following for each fish (if multiple are listed, cover each separately):

## 🐟 [Common Name] (*Latin/Scientific Name*)

### 📍 Origin & Habitat
- Natural location(s) of origin (rivers, oceans, regions)
- Natural habitat type (reef, river, lake, etc.)

### 📋 Key Facts
- Adult size
- Lifespan
- Diet (omnivore, carnivore, herbivore, and specific foods)
- Temperament (peaceful, semi-aggressive, aggressive)
- Swimming level (top, middle, bottom)

### ✨ Fun Facts
- 2–4 interesting or surprising facts about the species

### 🪣 Tank Care
- Minimum tank size
- Ideal water parameters (temperature, pH, salinity if applicable)
- Tank setup recommendations (substrate, plants, hiding spots, flow, etc.)
- Difficulty level (beginner, intermediate, expert)
''';

  if (tankSize != null && tankSize.isNotEmpty) {
    prompt += '''
- Notes on suitability for a $tankSize tank
''';
  }

  prompt += '''
### 🤝 Compatible Tank Mates
- List of species that are generally compatible
- Any species to avoid

---
Keep the response informative, accurate, and friendly. Use Markdown formatting for readability.
''';

  return prompt;
}
