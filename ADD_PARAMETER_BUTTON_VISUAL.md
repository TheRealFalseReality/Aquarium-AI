# Add Parameter Button - Visual Guide

## Tank Details Dialog - Empty State

When a tank has NO water parameters logged, the dialog now shows:

```
╔═══════════════════════════════════════════════════════╗
║  🟦  My Reef Tank                                  ✕  ║
║      Saltwater Tank                                   ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  📏 55 gal   ⚖️ 458 lbs   🐠 3 fish                   ║
║                                                       ║
║  ┌─────────────────────────────────────────────────┐ ║
║  │  📸 Photos                                      │ ║
║  │  ┌───┐ ┌───┐ ┌───┐                             │ ║
║  │  │ 🖼️│ │ 🖼️│ │ 🖼️│                             │ ║
║  │  └───┘ └───┘ └───┘                             │ ║
║  └─────────────────────────────────────────────────┘ ║
║                                                       ║
║  ┌─────────────────────────────────────────────────┐ ║
║  │  🧪 Parameters                                  │ ║ ← NEW SECTION
║  │                                                 │ ║
║  │              💧                                 │ ║ ← Empty state icon
║  │                                                 │ ║
║  │      No parameters logged yet                  │ ║
║  │                                                 │ ║
║  │      Start tracking your water parameters      │ ║
║  │      to monitor your aquarium's health         │ ║
║  │                                                 │ ║
║  │         ┌────────────────────┐                 │ ║
║  │         │ ➕ Add Parameter   │                 │ ║ ← NEW BUTTON
║  │         └────────────────────┘                 │ ║
║  │                                                 │ ║
║  └─────────────────────────────────────────────────┘ ║
║                                                       ║
║  ┌─────────────────────────────────────────────────┐ ║
║  │  🐠 Inhabitants (3)                            ▼│ ║
║  └─────────────────────────────────────────────────┘ ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

## Tank Details Dialog - With Parameters

When a tank HAS water parameters logged (existing behavior, unchanged):

```
╔═══════════════════════════════════════════════════════╗
║  🟦  My Reef Tank                                  ✕  ║
║      Saltwater Tank                                   ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  📏 55 gal   ⚖️ 458 lbs   🐠 3 fish                   ║
║                                                       ║
║  ┌─────────────────────────────────────────────────┐ ║
║  │  🧪 Parameters        [ 📝 Manage ]             │ ║ ← Existing section
║  │                                                 │ ║
║  │  ⚠️ Ammonia: 0.0 ppm      📊 Nitrate: 5.0 ppm  │ ║
║  │  🔬 Nitrite: 0.0 ppm      💧 Salinity: 35 ppt  │ ║
║  │                                                 │ ║
║  └─────────────────────────────────────────────────┘ ║
║                                                       ║
║  ┌─────────────────────────────────────────────────┐ ║
║  │  🐠 Inhabitants (3)                            ▼│ ║
║  └─────────────────────────────────────────────────┘ ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

## Comparison: Before vs After

### BEFORE (No Parameters)
The Parameters section was completely hidden:

```
Tank Details
├── Header
├── Stats
├── Photos (if any)
└── Inhabitants       ⚠️ No way to add parameters from here
```

### AFTER (No Parameters)
The Parameters section is now visible with a call-to-action:

```
Tank Details
├── Header
├── Stats
├── Photos (if any)
├── Parameters        ✅ NEW: Empty state with "Add Parameter" button
└── Inhabitants
```

## User Interaction Flow

```
┌────────────────┐
│  Tank Details  │  User opens tank details dialog
│     Dialog     │
└───────┬────────┘
        │
        ▼
   ┌─────────┐     No parameters logged?
   │  Check  │────────► YES ──┐
   └─────────┘                 │
        │                      │
        │ NO (has params)      │
        │                      ▼
        │              ┌──────────────────┐
        │              │  Show Empty      │
        │              │  State Section   │
        │              └────────┬─────────┘
        │                       │
        │              User clicks "Add Parameter"
        │                       │
        │                       ▼
        │              ┌──────────────────┐
        │              │  Close Dialog    │
        │              └────────┬─────────┘
        │                       │
        │                       ▼
        │              ┌──────────────────┐
        │              │  Navigate to     │
        │              │ Parameter Logger │
        │              │     Screen       │
        │              └──────────────────┘
        │
        ▼
┌──────────────────┐
│  Show Existing   │
│  Parameters +    │
│  Manage Button   │
└──────────────────┘
```

## Design Details

### Empty State Section
- **Container**: Rounded corners (12px), border with opacity, semi-transparent background
- **Header**: "Parameters" with science icon, medium title weight
- **Icon**: Water drop outline, 48px, muted color
- **Primary Text**: "No parameters logged yet", medium weight
- **Secondary Text**: Explanatory text, small font, muted color, centered
- **Button**: FilledButton with:
  - Icon: Plus sign (18px)
  - Label: "Add Parameter"
  - Padding: 16px horizontal, 12px vertical
  - Material Design filled button style

### Spacing
- 16px padding around section content
- 16px between icon and text elements
- 12px between primary and secondary text
- 16px between text and button
- 16px margin after section

### Colors (Theme-aware)
All colors use Material 3 theme tokens:
- Container background: `surfaceContainerHigh` with 50% opacity
- Border: `outlineVariant` with 40% opacity
- Icon: `onSurfaceVariant` with 50% opacity
- Text: `onSurfaceVariant` (various opacities)
- Button: Standard `FilledButton` theme colors

## Accessibility

- Clear visual hierarchy
- Descriptive text explains the feature
- Button has both icon and text label
- Uses semantic widgets (FilledButton)
- Theme-aware colors for light/dark mode
- Sufficient contrast ratios

## Responsive Behavior

The section inherits responsive behavior from the dialog:
- Mobile: Horizontal padding 16px
- Desktop: Horizontal padding 40px
- Maximum width: 700px on desktop
- Scrollable when content exceeds viewport height
