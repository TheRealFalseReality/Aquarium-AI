# AI Stocking Recommendations Button - UI Changes

## Overview
Reworked the AI stocking recommendations button from an inline button within each tank card to a floating action button (FAB) positioned in the bottom right corner of the screen.

## Changes Made

### Before
- **Location**: Inside each tank card, below the notes section
- **Appearance**: Full-width button with text label "AI Stocking Recommendations" and icon
- **Size**: Height 36px, full width of the card
- **Gradient**: Purple → Blue → Cyan (with purple shadow)

### After
- **Location**: Bottom right corner of the screen (floating)
- **Appearance**: Icon-only circular FAB with auto_awesome icon
- **Size**: 56x56px circle
- **Position**: 16px from right edge, 16px from bottom edge
- **Gradient**: Same gradient (Purple → Blue → Cyan)
- **Shadow**: Enhanced purple shadow for better visibility

## Visual Layout

```
┌─────────────────────────────────────────────┐
│  My Tanks                           [≡]     │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ 🐟 Tank Name                    [⋮]  │  │
│  │ Freshwater                           │  │
│  │                                       │  │
│  │ Size: 55 gal | Harmony: 85%          │  │
│  │                                       │  │
│  │ 🐟 Inhabitants (12)                  │  │
│  │ • 5x Neon Tetra                      │  │
│  │ • 3x Guppy                           │  │
│  │                                       │  │
│  │ 📝 Notes: Beautiful community tank   │  │
│  │                                       │  │
│  │ Created 2024-01-15                   │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ Another Tank Card...                 │  │
│  └──────────────────────────────────────┘  │
│                                             │
│                                         ┌─┐ │
│                                         │✨│ │ ← New FAB!
│                                         └─┘ │
│                          [+ Create Tank]    │
└─────────────────────────────────────────────┘
```

## Technical Implementation

### Component Structure
```dart
Widget _buildAIStockingFAB(BuildContext context, WidgetRef ref, Tank tank) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.purple.shade400,   // Purple start
          Colors.blue.shade500,     // Blue middle
          Colors.cyan.shade400,     // Cyan end
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.purple.withOpacity(0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _getTankStockingRecommendations(context, ref, tank),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    ),
  );
}
```

### Positioning
The FAB is added to the Stack in `_buildTankListWithFloatingMenu`:
```dart
if (hasInhabitants)
  Positioned(
    right: 16,
    bottom: 16,
    child: _buildAIStockingFAB(context, ref, tanksWithInhabitants.first),
  ),
```

## Behavior

1. **Visibility**: The FAB only appears when there is at least one tank with inhabitants
2. **Action**: Tapping the FAB triggers the AI stocking recommendations for the first tank with inhabitants
3. **Interaction**: Includes ripple effect on tap (Material InkWell)
4. **Alternative Access**: The "Get Stocking Ideas" option remains in the three-dot menu of each tank card

## Benefits

1. **Space Efficiency**: Removes the large button from each card, making cards more compact
2. **Consistent Access**: Single, easily accessible button for AI recommendations
3. **Better UX**: Floating button is more discoverable and follows Material Design patterns
4. **Visual Clarity**: Icon-only design is cleaner and less cluttered

## Files Modified

- `lib/screens/tank_management_screen.dart`
  - Added `_selectedTankForStocking` state variable (line 39)
  - Modified `_buildTankListWithFloatingMenu` to include FAB (lines 268-299)
  - Added `_buildAIStockingFAB` method (lines 628-667)
  - Removed inline button from tank cards (removed ~57 lines)

## Gradient Colors
The same gradient is maintained from the original design:
- **Purple**: `Colors.purple.shade400` (#AB47BC)
- **Blue**: `Colors.blue.shade500` (#2196F3)
- **Cyan**: `Colors.cyan.shade400` (#26C6DA)

## Shadow Effect
- **Color**: Purple with 40% opacity
- **Blur**: 12px
- **Offset**: (0, 4) - 4px down from center
