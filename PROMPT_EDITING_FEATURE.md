# Editable AI Prompts Feature

This feature allows users to customize all AI prompts used throughout the Aquarium AI application.

## Overview

The Aquarium AI app uses 7 different types of prompts for various AI tasks:

1. **System Prompt** - The core personality and instructions for the AI chatbot
2. **Photo Analysis Prompt** - Instructions for analyzing aquarium photos
3. **Automation Script Prompt** - Instructions for generating Home Assistant/ESPHome automation scripts
4. **Water Analysis Prompt** - Instructions for analyzing water parameter data
5. **Fish Compatibility Prompt** - Instructions for analyzing fish compatibility
6. **Stocking Recommendation Prompt** - Instructions for recommending fish stocking plans
7. **Tank Stocking Recommendation Prompt** - Instructions for recommending additional fish for existing tanks

## How to Access

1. Open the app and navigate to **Settings**
2. Scroll down to find the **AI Prompt Settings** section
3. Each prompt type is displayed as an expandable card

## How to Edit Prompts

### Creating a Custom Prompt
1. Tap on any prompt card to expand it
2. For default prompts, click **"Create Custom Version"**
3. The prompt editor will open with the default prompt pre-filled
4. Edit the text as needed
5. Click **"Save"** to store your custom prompt

### Template Variables
Some prompts use template variables that get replaced with actual values:
- `{userNote}` - User's note about the photo
- `{description}` - Automation description
- `{tankType}` - Type of aquarium
- `{temp}` - Temperature value
- `{tempUnit}` - Temperature unit
- `{ph_line}` - pH information line
- etc.

Keep these variables in your custom prompts to maintain functionality.

### Viewing Custom vs Default
- Custom prompts show a **"Custom"** badge
- You can expand **"View Default Prompt"** to see the original
- Default prompts are shown as read-only

## Managing Prompts

### Restore Individual Prompt
1. Expand a custom prompt card
2. Click **"🔄 Restore Default"** button
3. Confirm the action to reset that specific prompt

### Reset All Prompts
1. In the AI Prompt Settings section
2. Click **"🔄 Reset All Prompts"**
3. Confirm to reset all prompts to defaults

### Preview Prompts
1. For custom prompts, click **"👁️ Preview"**
2. View the full prompt text in a dialog

## Technical Implementation

### Storage
- Custom prompts are stored in `SharedPreferences`
- Keys: `custom_prompt_{promptType}`
- Fallback to defaults when no custom prompt exists

### Provider Architecture
- `PromptProvider` manages all prompt state
- `PromptNotifier` handles CRUD operations
- Integration with existing providers for seamless functionality

### Template System
- Template variables use `{variable}` syntax
- Runtime replacement in prompt building functions
- Backward compatibility with existing code

## Files Modified

### Core Files
- `lib/providers/prompt_provider.dart` - Main prompt management
- `lib/screens/settings_screen.dart` - UI implementation

### Prompt Files (Updated for custom support)
- `lib/prompts/system_prompt.dart`
- `lib/prompts/photo_analysis_prompt.dart`
- `lib/prompts/automation_script_prompt.dart`
- `lib/prompts/water_analysis_prompt.dart`
- `lib/prompts/fish_compatibility_prompt.dart`
- `lib/prompts/stocking_recommendation_prompt.dart`
- `lib/prompts/tank_stocking_recommendation_prompt.dart`

### Provider Integration
- `lib/providers/fish_compatibility_provider.dart`
- `lib/providers/aquarium_stocking_provider.dart`
- `lib/providers/system_prompt_provider.dart` - Helper for system prompt access

### Tests
- `test/prompt_provider_test.dart` - Unit tests for prompt provider
- `test/prompt_integration_test.dart` - Integration tests for prompt building

## Benefits

1. **Customization** - Users can tailor AI behavior to their specific needs
2. **Experimentation** - Try different prompt styles and approaches
3. **Flexibility** - Adapt prompts for different use cases or languages
4. **Safety** - Always able to restore to known-good defaults
5. **Transparency** - Users can see exactly what instructions the AI receives

## Usage Examples

### Custom System Prompt
```
You are AquaBot, a friendly aquarium assistant specializing in beginner-friendly advice.

Always:
- Use simple, easy-to-understand language
- Provide step-by-step instructions
- Include safety warnings when relevant
- Suggest AquaPi products when appropriate

Focus on:
- Beginner aquarium setup
- Common fish species
- Basic water chemistry
```

### Custom Photo Analysis
```
Analyze this aquarium photo focusing on:
1. Fish health indicators
2. Water clarity assessment
3. Equipment visibility check
4. Overall tank aesthetics

User context: {userNote}

Provide JSON response with detailed observations.
```

This feature provides powerful customization while maintaining the app's core functionality and user experience.