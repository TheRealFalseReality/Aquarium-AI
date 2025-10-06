# Species Tags Feature Documentation

## Overview
The Species Tags feature allows users to add custom species names (tags) to fish types in the application. This enhances searchability and organization within the Fish Compatibility Tool and prepares the groundwork for future search capabilities in Tank Management.

## Features Implemented

### 1. Species Tags Model (`lib/models/species_tag.dart`)
- **Purpose**: Data model for storing fish type and associated species tags
- **Key Methods**:
  - `toJson()`: Converts to JSON for storage
  - `fromJson()`: Creates instance from JSON
  - `copyWith()`: Creates a copy with updated values

### 2. Species Tags Provider (`lib/providers/species_tags_provider.dart`)
- **Purpose**: State management and persistence for species tags
- **Storage**: Uses `SharedPreferences` for local storage
- **Key Features**:
  - Add/remove/update tags for fish types
  - Search fish types by tag
  - Persist tags across app sessions
  - Case-insensitive tag searching
- **Key Methods**:
  - `setTagsForFishType(fishType, tags)`: Set or update tags for a fish type
  - `addTag(fishType, tag)`: Add a single tag (prevents duplicates)
  - `removeTag(fishType, tag)`: Remove a specific tag
  - `getTagsForFishType(fishType)`: Get all tags for a fish type
  - `searchByTag(tag)`: Find fish types containing a tag
  - `clearAllTags()`: Remove all tags

### 3. Species Tags Management Screen (`lib/screens/species_tags_screen.dart`)
- **Route**: `/species-tags`
- **Purpose**: Full-screen interface for managing species tags
- **Features**:
  - Switch between freshwater and marine categories
  - Search fish types by name, common names, or tags
  - Add tags via dialog with text input
  - Edit multiple tags at once (comma-separated)
  - Delete individual tags with chip delete button
  - Visual feedback with chips for each tag
  - Analytics tracking for user actions

### 4. Integration Points

#### Settings Screen (`lib/screens/settings_screen.dart`)
- **Location**: App Settings section, below "Show AI Stocking Button"
- **UI Element**: ListTile with label icon, title, subtitle, and arrow
- **Navigation**: Taps navigate to Species Tags screen

#### Fish Compatibility Screen (`lib/screens/fish_compatibility_screen.dart`)
- **Location**: Search bar (when expanded)
- **UI Element**: Subtle link below search input: "Manage species tags"
- **Enhanced Search**: Search now includes species tags alongside fish names and common names
- **Example**: Searching for "Neon" will find fish types tagged with "Neon Tetra"

### 5. Tests

#### Model Tests (`test/models/species_tag_test.dart`)
- Creation with tags and empty tags
- JSON serialization/deserialization
- copyWith method functionality
- Roundtrip conversion testing

#### Provider Tests (`test/providers/species_tags_provider_test.dart`)
- Initial state verification
- Adding/removing/updating tags
- Duplicate prevention
- Search functionality (case-insensitive)
- Persistence across provider instances
- Empty list handling

## Usage Flow

### For Users:
1. **Access via Settings**:
   - Open Settings screen
   - Find "Species Tags" in App Settings section
   - Tap to open Species Tags screen

2. **Access via Fish Compatibility Tool**:
   - Open Fish Compatibility screen
   - Tap search button
   - Tap "Manage species tags" link below search bar

3. **Adding Tags**:
   - Select category (freshwater/saltwater)
   - Find fish type in list
   - Tap "+" button
   - Enter species name (e.g., "Neon Tetra")
   - Tap "Add"

4. **Editing Tags**:
   - Tap "Edit" button on fish type with tags
   - Modify comma-separated list
   - Tap "Save"

5. **Removing Tags**:
   - Tap "X" on individual tag chips
   - Or edit and remove from comma-separated list

6. **Searching with Tags**:
   - In Fish Compatibility screen, use search
   - Type species name (e.g., "Neon")
   - Fish types with matching tags appear

## Technical Details

### Data Storage
- **Key**: `species_tags`
- **Format**: JSON string in SharedPreferences
- **Structure**: `Map<String, List<String>>` where key is fish type and value is list of tags
- **Example**:
```json
{
  "Barbs": ["Tiger Barb", "Cherry Barb", "Rosy Barb"],
  "Tetras": ["Neon Tetra", "Cardinal Tetra", "Black Skirt Tetra"]
}
```

### State Management
- Uses Riverpod's `StateNotifierProvider`
- Reactive updates across the app
- Automatic persistence on changes

### Analytics Tracking
- Screen visits: `species_tags_screen`
- Tag additions: `species_tag_added`
- Tag edits: `species_tags_edited`

## Future Enhancements

### Planned:
1. **Default Species Tags**: Pre-populate common species names for fish types
2. **Tag Suggestions**: Auto-complete based on existing tags
3. **Tank Management Search**: Add search to tank management that includes species tags
4. **Export/Import**: Allow users to share tag collections
5. **Cloud Sync**: Optional cloud backup of tags
6. **Tag Statistics**: Show most commonly tagged species

### Possible:
- Tag categories (scientific names, common names, regional names)
- Multi-language support for tags
- Community-shared tag collections
- Image recognition to suggest tags

## Code Structure

```
lib/
├── models/
│   └── species_tag.dart           # Data model
├── providers/
│   └── species_tags_provider.dart # State management
├── screens/
│   ├── species_tags_screen.dart   # Main management UI
│   ├── settings_screen.dart       # Added navigation link
│   └── fish_compatibility_screen.dart # Search integration
└── main.dart                      # Added route

test/
├── models/
│   └── species_tag_test.dart      # Model tests
└── providers/
    └── species_tags_provider_test.dart # Provider tests
```

## Migration Notes
- No database migration needed (new feature)
- No breaking changes to existing functionality
- Tags are optional; all features work without tags
- Backwards compatible with previous app versions

## Known Limitations
1. Tags are stored locally only (no cloud sync yet)
2. No default tags provided (planned for future)
3. Tank Management screen doesn't have search yet (tags are ready for when it's added)
4. No tag validation (users can add any text)

## Testing Checklist
- [x] Model serialization/deserialization
- [x] Provider state management
- [x] Tag CRUD operations
- [x] Search functionality
- [x] Persistence across sessions
- [ ] UI interaction testing (requires Flutter environment)
- [ ] Integration testing with real fish data
- [ ] Performance testing with large numbers of tags

## Accessibility
- All interactive elements have proper labels
- Screen reader support via `accessible_feedback` widget
- Keyboard navigation support
- Visual feedback for all actions

## Performance Considerations
- Tags loaded once at app start
- Efficient search using built-in Dart string methods
- Minimal memory footprint (only active tags stored)
- No network requests (local storage only)

## Security & Privacy
- All data stored locally on device
- No personal information collected
- No external service integration
- User has full control over their data
