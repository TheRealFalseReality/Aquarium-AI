# Tank Photos Feature

## Overview
This feature adds the ability for users to add photos of their tanks (not fish) with a date taken field to track the tank's progress over time.

## Implementation Details

### 1. Model Changes (`lib/models/tank.dart`)

#### New Class: `TankPhoto`
- **id**: Unique identifier for the photo
- **imageUrl**: Optional URL for remote images
- **imagePath**: Optional local file path for device images
- **dateTaken**: Date when the photo was taken (defaults to today when adding new photo)
- **Methods**: `toJson()`, `fromJson()`, `copyWith()`

#### Updated Class: `Tank`
- Added `photos` field: `List<TankPhoto>` to store tank photos
- Updated `toJson()`, `fromJson()`, and `copyWith()` methods to handle photos
- Backwards compatible - if photos field is missing in JSON, defaults to empty list

### 2. UI Changes (`lib/screens/tank_creation_screen.dart`)

#### State Management
- Added `_tankPhotos` list to manage tank photos
- Initialized from `existingTank.photos` when editing
- Saved to tank when creating or updating

#### New Methods
- `_addTankPhoto()`: Opens dialog to add new tank photo
- `_editTankPhoto(int index)`: Opens dialog to edit existing photo
- `_removeTankPhoto(int index)`: Removes photo from list
- `_buildTankPhotoThumbnail(TankPhoto photo, int index)`: Builds thumbnail widget for each photo

#### New Widget: `_TankPhotoDialog`
A dialog for adding/editing tank photos with:
- Image source selection (Gallery, Camera, or URL)
- Image preview
- Date taken picker (defaults to today)
- Form validation

#### Tank Photos Section
Added after the Inhabitants section:
- Shows "No tank photos added yet" message when empty
- Displays thumbnails in a wrap layout when photos exist
- Each thumbnail shows:
  - The image
  - Date taken badge at the bottom
  - Edit and delete buttons

### 3. Display Changes (`lib/screens/tank_management_screen.dart`)

Added tank photos display in tank cards:
- Shows "Tank Photos (count)" label
- Horizontal scrollable list of thumbnails
- Each thumbnail is 60x60 pixels with rounded corners
- Only shows section if photos exist

### 4. Tests (`test/models/tank_test.dart`)

Created comprehensive tests for:
- TankPhoto serialization/deserialization
- TankPhoto copyWith functionality
- Tank with photos integration
- Backwards compatibility (Tank without photos field)

## User Experience

### Adding Photos
1. Open tank creation/edit screen
2. Scroll to "Tank Photos" section
3. Click "Add Photo" button
4. Choose image source (Gallery, Camera, or URL)
5. Select or adjust "Date Taken" (defaults to today)
6. Click "Add"

### Editing Photos
1. Click edit button on photo thumbnail
2. Update image or date taken
3. Click "Update"

### Deleting Photos
1. Click delete button on photo thumbnail

### Viewing Photos
- Photos appear as small thumbnails in tank cards on the management screen
- Each thumbnail shows the date taken
- Photos can be scrolled horizontally if there are multiple

## Technical Notes

### Image Handling
- Supports both local images (via ImagePicker) and remote URLs
- Uses same pattern as fish inhabitant custom images
- Images are displayed using Flutter's Image.network() or Image.file()
- Error handling for failed image loads

### Date Handling
- All dates stored as DateTime objects
- Serialized as ISO 8601 strings in JSON
- Date picker allows selection from year 2000 to today
- Default date is always today when adding new photo

### Backwards Compatibility
- Existing tanks without photos field will work correctly
- JSON deserialization handles missing photos field by defaulting to empty list
- No migration required

## Future Enhancements (Not Implemented)
- Photo captions/notes
- Full-screen photo viewer
- Photo comparison slider
- Automatic photo timeline
- Photo tags/categories
- Bulk photo upload
