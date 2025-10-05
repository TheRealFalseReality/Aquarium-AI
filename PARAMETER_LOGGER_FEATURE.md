# Parameter Logger Feature

## Overview
The Parameter Logger feature allows users to track water parameters for their aquarium tanks over time. Users can log readings for ammonia, nitrite, nitrate, phosphate, and salinity with timestamps and optional notes.

## Access
The Parameter Logger can be accessed from the tank's 3-dot menu in the Tank Management screen:
1. Navigate to Tank Management
2. Find the tank you want to track parameters for
3. Click the 3-dot menu (⋮) on the tank card
4. Select "Parameter Logger"

## Features

### Supported Parameters
- **Ammonia** - measured in ppm or mg/L
- **Nitrite** - measured in ppm or mg/L
- **Nitrate** - measured in ppm or mg/L
- **Phosphate** - measured in ppm or mg/L
- **Salinity** - measured in ppt or SG (Specific Gravity)

### Functionality
- **Add Readings**: Log new parameter readings with date/time, value, unit, and optional notes
- **View History**: Parameters are grouped by type and sorted by date (newest first)
- **Expandable Groups**: Click on a parameter type to expand and view all readings
- **Delete Readings**: Remove individual parameter readings
- **Persistence**: All readings are automatically saved with the tank data

## Implementation Details

### New Model
**WaterParameter** (`lib/models/water_parameter.dart`)
- `id`: Unique identifier
- `parameterType`: Type of parameter (ammonia, nitrite, nitrate, phosphate, salinity)
- `value`: Numeric value of the reading
- `unit`: Unit of measurement (ppm, mg/L, ppt, SG)
- `dateRecorded`: Timestamp of when the reading was taken
- `notes`: Optional notes about the reading

### Updated Models
**Tank** (`lib/models/tank.dart`)
- Added `waterParameters` field to store list of water parameter readings
- Updated JSON serialization/deserialization to include water parameters
- Backward compatible with existing tank data (empty list if not present)

### New Screen
**ParameterLoggerScreen** (`lib/screens/parameter_logger_screen.dart`)
- Displays all water parameter readings grouped by type
- Modal bottom sheet for adding new readings
- Date/time picker for recording when measurements were taken
- Expandable cards for each parameter type
- Delete confirmation dialog

### UI Components
- Color-coded parameter types for easy identification
- Icon-based visual indicators for each parameter
- Empty state with call-to-action for first reading
- Floating action button for quick access to add readings
- Clean, Material Design 3 interface

## Data Persistence
Water parameters are stored with the tank data and persisted via the existing TankProvider. All changes are automatically saved to SharedPreferences.

## Testing
Tests have been added for:
- WaterParameter model serialization/deserialization
- Tank model backward compatibility with waterParameters field
- Model factory methods and copy operations

## Future Enhancements (Potential)
- Charts/graphs to visualize parameter trends over time
- Parameter alerts when readings are out of ideal ranges
- Export parameter history to CSV
- Reminders to test water parameters regularly
- Integration with water parameter analysis AI
