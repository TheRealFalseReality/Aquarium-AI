# Species Tags - Quick Start Guide

## For Developers

### What is this feature?
Species Tags allows users to add custom species names to fish types, making them searchable in the Fish Compatibility Tool.

### Quick Integration Check
```dart
// 1. Check if species tags provider is imported
import '../providers/species_tags_provider.dart';

// 2. Access tags in your widget
final tags = ref.read(speciesTagsProvider).tags;

// 3. Get tags for a specific fish type
final barberTags = ref.read(speciesTagsProvider.notifier).getTagsForFishType('Barbs');
```

### File Structure
```
lib/
├── models/species_tag.dart          # Data model
├── providers/species_tags_provider.dart  # State management
├── screens/species_tags_screen.dart      # Management UI
└── screens/
    ├── settings_screen.dart         # Link added
    └── fish_compatibility_screen.dart    # Search integration

test/
├── models/species_tag_test.dart     # Model tests
└── providers/species_tags_provider_test.dart  # Provider tests
```

### Key Methods

#### SpeciesTagsNotifier
```dart
// Add a tag
await notifier.addTag('Barbs', 'Tiger Barb');

// Remove a tag
await notifier.removeTag('Barbs', 'Tiger Barb');

// Set all tags for a fish type
await notifier.setTagsForFishType('Barbs', ['Tiger Barb', 'Cherry Barb']);

// Get tags
List<String> tags = notifier.getTagsForFishType('Barbs');

// Search by tag
List<String> fishTypes = notifier.searchByTag('tetra');

// Check if fish has tags
bool hasTags = notifier.hasTags('Barbs');
```

### Navigation Routes
```dart
// Navigate to species tags screen
Navigator.pushNamed(context, '/species-tags');
```

### Data Storage
- **Location**: SharedPreferences
- **Key**: `species_tags`
- **Format**: JSON string of `Map<String, List<String>>`

---

## For Users

### How to Add Species Tags

#### Method 1: From Settings
1. Open **Settings** from the app menu
2. Scroll to **App Settings** section
3. Tap **Species Tags**
4. Select category (Freshwater/Saltwater)
5. Find the fish type you want to tag
6. Tap the **+** button
7. Enter the species name (e.g., "Neon Tetra")
8. Tap **Add**

#### Method 2: From Fish Compatibility
1. Open **Fish Compatibility** screen
2. Tap the **Search** button
3. Look for **"Manage species tags"** link below the search bar
4. Tap the link
5. Follow steps 4-8 from Method 1

### How to Use Tags in Search
1. Open **Fish Compatibility** screen
2. Tap the **Search** button
3. Type a species name (e.g., "Neon")
4. Fish types with matching tags will appear in results
5. Select fish and continue as normal

### How to Edit Tags
1. Go to **Species Tags** screen
2. Find fish type with existing tags
3. Tap the **Edit** button (pencil icon)
4. Modify the comma-separated list
5. Tap **Save**

### How to Delete a Tag
1. Go to **Species Tags** screen
2. Find fish type with tags
3. Tap the **X** on the tag chip you want to remove
4. Tag is immediately deleted

---

## For Testers

### Test Scenarios

#### Basic Functionality
- [ ] Add a tag to a fish type
- [ ] Remove a tag from a fish type
- [ ] Edit multiple tags at once
- [ ] Search for fish using tags
- [ ] Tags persist after closing app

#### Navigation
- [ ] Access from Settings screen
- [ ] Access from Fish Compatibility screen
- [ ] Back navigation works correctly

#### Edge Cases
- [ ] Add duplicate tag (should be prevented)
- [ ] Add empty tag (should be rejected)
- [ ] Search with no matches
- [ ] Fish type with many tags displays correctly
- [ ] Very long tag names

#### Platform Specific
- [ ] Works on Android
- [ ] Works on iOS
- [ ] Works on Web
- [ ] Keyboard navigation works
- [ ] Screen reader announces correctly

### Expected Behavior

#### Adding Tags
- Dialog appears with text input
- User enters species name
- Taps Add button
- Tag appears as a chip below fish name
- Success message shows

#### Searching
- User types in search bar
- Fish types with matching tags appear
- Matching is case-insensitive
- Search includes fish name, common names, and tags

#### Performance
- Screen loads quickly (<500ms)
- Search is responsive
- No lag when adding/removing tags
- Scrolling is smooth

---

## Troubleshooting

### Tags Not Saving
- Check that SharedPreferences is working
- Verify `species_tags` key in storage
- Check for exceptions in logs

### Tags Not Appearing in Search
- Verify tags are set correctly
- Check case sensitivity
- Ensure provider is read correctly in search code

### Navigation Issues
- Verify route is registered in `main.dart`
- Check that links are tappable
- Verify Navigator.pushNamed is called correctly

### UI Issues
- Check theme compatibility
- Verify widget tree structure
- Test on different screen sizes

---

## Quick Reference

### Accessing Tags in Code
```dart
// Read only (doesn't rebuild on changes)
final tags = ref.read(speciesTagsProvider).tags;

// Watch (rebuilds on changes)
final tagsState = ref.watch(speciesTagsProvider);

// Get notifier for methods
final notifier = ref.read(speciesTagsProvider.notifier);
```

### Storage Format
```json
{
  "Barbs": ["Tiger Barb", "Cherry Barb", "Rosy Barb"],
  "Tetras": ["Neon Tetra", "Cardinal Tetra"],
  "Guppies": ["Fancy Guppy", "Endler Guppy"]
}
```

### Analytics Events
- `species_tags_screen` - Screen opened
- `species_tag_added` - Tag added to fish type
- `species_tags_edited` - Tags edited for fish type

---

## Need More Info?

- **Technical Details**: See `SPECIES_TAGS_FEATURE.md`
- **UI/UX Design**: See `SPECIES_TAGS_UI_GUIDE.md`
- **Implementation**: See `IMPLEMENTATION_SUMMARY.md`

---

## Version
**Version**: 1.0  
**Last Updated**: 2024  
**Status**: ✅ Production Ready
