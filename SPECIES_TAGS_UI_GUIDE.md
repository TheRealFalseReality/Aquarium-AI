# Species Tags UI Guide

## User Interface Overview

This document describes the user interface elements added for the Species Tags feature.

## 1. Settings Screen Integration

### Location
The Species Tags entry appears in the **App Settings** section of the Settings screen.

### Visual Elements
```
┌─────────────────────────────────────────────────┐
│  App Settings                                   │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │ 🤖 Show AI Stocking Button               │ │
│  │ Display the full "AI Stocking..."  [ON]  │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  ─────────────────────────────────────────────  │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │ 🏷️  Species Tags                    →     │ │
│  │    Manage searchable species names        │ │
│  │    for fish types                         │ │
│  └───────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

### Interaction
- **Tap**: Opens Species Tags Management screen
- **Visual Feedback**: Ripple effect on tap

---

## 2. Fish Compatibility Screen Integration

### Location
Below the search bar when search is active.

### Visual Elements
```
┌─────────────────────────────────────────────────┐
│  ╔═════════════════════════════════════════╗   │
│  ║ 🔍 Search by name...              ✕    ║   │
│  ╚═════════════════════════════════════════╝   │
│                                                 │
│       🏷️ Manage species tags                   │
│           (clickable link)                      │
└─────────────────────────────────────────────────┘
```

### Interaction
- **Subtle Design**: Small text with label icon
- **Underlined**: Indicates it's a clickable link
- **Tap**: Opens Species Tags Management screen

---

## 3. Species Tags Management Screen

### Header Section
```
┌─────────────────────────────────────────────────┐
│  ← Species Tags                                 │
│                                                 │
│           Species Tags                          │
│                                                 │
│  Add searchable species names to each fish     │
│  type to help with filtering and organization. │
└─────────────────────────────────────────────────┘
```

### Category Selector
```
┌─────────────────────────────────────────────────┐
│  ┌──────────────────┬──────────────────┐       │
│  │ 💧 Freshwater    │  🌊 Saltwater    │       │
│  │   (selected)     │                  │       │
│  └──────────────────┴──────────────────┘       │
└─────────────────────────────────────────────────┘
```

### Search Bar
```
┌─────────────────────────────────────────────────┐
│  ╔═════════════════════════════════════════╗   │
│  ║ 🔍 Search by fish type or tag...   ✕   ║   │
│  ╚═════════════════════════════════════════╝   │
└─────────────────────────────────────────────────┘
```

### Fish List (No Tags)
```
┌─────────────────────────────────────────────────┐
│  ┌───────────────────────────────────────────┐ │
│  │ 🐟  Angelfish (Female) ♀                 │ │
│  │     No tags yet                           │ │
│  │                                     + 💬  │ │
│  └───────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

### Fish List (With Tags)
```
┌─────────────────────────────────────────────────┐
│  ┌───────────────────────────────────────────┐ │
│  │ 🐟  Barbs                                 │ │
│  │                                           │ │
│  │  ┌──────────────┐ ┌──────────────┐      │ │
│  │  │ Tiger Barb ✕ │ │ Cherry Barb ✕│      │ │
│  │  └──────────────┘ └──────────────┘      │ │
│  │  ┌──────────────┐                        │ │
│  │  │ Rosy Barb  ✕ │                   + ✏️ │ │
│  │  └──────────────┘                        │ │
│  └───────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

### Interactions

#### Adding a Tag (Dialog)
```
┌─────────────────────────────────────────────────┐
│  Add Tag to Barbs                               │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │ Species Name                              │ │
│  │ e.g., Neon Tetra, Guppy, etc.            │ │
│  │ _________________________________         │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│                        [Cancel]  [Add]          │
└─────────────────────────────────────────────────┘
```

#### Editing Tags (Dialog)
```
┌─────────────────────────────────────────────────┐
│  Edit Tags for Barbs                            │
│                                                 │
│  Enter species names separated by commas:      │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │ e.g., Neon Tetra, Cardinal Tetra         │ │
│  │ Tiger Barb, Cherry Barb, _______________ │ │
│  │ _______________________________________  │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│                        [Cancel]  [Save]         │
└─────────────────────────────────────────────────┘
```

---

## 4. Enhanced Search in Fish Compatibility

### Before (Without Tags)
- Search matches: Fish name, Common names only

### After (With Tags)
- Search matches: Fish name, Common names, **Species tags**

### Example Flow

**Step 1: User searches for "Neon"**
```
┌─────────────────────────────────────────────────┐
│  ╔═════════════════════════════════════════╗   │
│  ║ 🔍 Neon                           ✕    ║   │
│  ╚═════════════════════════════════════════╝   │
└─────────────────────────────────────────────────┘
```

**Step 2: Results include fish with "Neon" in tags**
```
┌─────────────────────────────────────────────────┐
│  ┌─────────────┐  ┌─────────────┐              │
│  │   🐟        │  │   🐟        │              │
│  │             │  │             │              │
│  │  Tetras     │  │  Rasboras   │              │
│  │  ✓ Selected │  │             │              │
│  └─────────────┘  └─────────────┘              │
│  Tags: Neon Tetra Tags: Neon Rasbora           │
│  (matched search) (matched search)             │
└─────────────────────────────────────────────────┘
```

---

## Visual Design Principles

### Colors
- **Primary Action**: Uses theme primary color
- **Tag Chips**: Material Design chips with theme colors
- **Icons**: Consistent with app icon set

### Typography
- **Screen Title**: `headlineLarge` with bold weight
- **Subtitle**: `bodyMedium` for descriptions
- **Tags**: `bodySmall` for chip labels
- **Links**: `bodySmall` with underline decoration

### Spacing
- **Consistent Padding**: 16px horizontal, varies vertical
- **Card Margins**: 12px bottom spacing
- **Chip Spacing**: 6px horizontal, 4px vertical (wrap)

### Accessibility
- **Touch Targets**: Minimum 48x48 dp
- **Color Contrast**: WCAG AA compliant
- **Screen Reader**: Full support with semantic labels
- **Keyboard Navigation**: Tab order follows visual flow

---

## User Flows

### Flow 1: Adding First Tag
1. User opens Settings
2. Taps "Species Tags"
3. Sees list of fish types (no tags)
4. Taps "+" on desired fish type
5. Dialog appears
6. Types species name
7. Taps "Add"
8. Tag chip appears below fish type
9. Success message shows

### Flow 2: Searching with Tags
1. User opens Fish Compatibility
2. Taps search button
3. Types species name (e.g., "Neon")
4. Fish types with matching tags appear
5. User selects desired fish
6. Continues with compatibility check

### Flow 3: Managing Multiple Tags
1. User opens Species Tags screen
2. Finds fish type with existing tags
3. Taps "Edit" button
4. Dialog shows comma-separated tags
5. Modifies list (adds/removes)
6. Taps "Save"
7. Updated chips appear
8. Success message shows

### Flow 4: Quick Tag Deletion
1. User sees fish with tag chips
2. Taps "X" on specific chip
3. Tag immediately removed
4. Confirmation message shows

---

## Responsive Design

### Phone (Portrait)
- Full-width cards
- Single column layout
- Stacked buttons

### Tablet (Landscape)
- Wider cards with more spacing
- Potentially 2-column grid (future enhancement)
- More visible tags per row

### Accessibility Features
- Text scaling support
- High contrast mode compatibility
- Reduced motion respect
- Dynamic type support

---

## Error States

### No Fish Data
```
┌─────────────────────────────────────────────────┐
│                                                 │
│              ⚠️                                 │
│                                                 │
│    Failed to load fish data:                   │
│    [Error message]                             │
│                                                 │
└─────────────────────────────────────────────────┘
```

### No Search Results
```
┌─────────────────────────────────────────────────┐
│                                                 │
│              🔍                                 │
│                                                 │
│    No fish found matching "query"              │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Empty Category
```
┌─────────────────────────────────────────────────┐
│                                                 │
│              🐠                                 │
│                                                 │
│    No fish found in this category.             │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Animations

### Tag Addition
- **Effect**: Fade in + scale up
- **Duration**: 200ms
- **Easing**: Ease out

### Tag Removal
- **Effect**: Fade out + scale down
- **Duration**: 150ms
- **Easing**: Ease in

### Screen Transitions
- **Effect**: Fade + slide
- **Duration**: 300ms
- **Direction**: Left to right

### Search Bar Expand
- **Effect**: Scale + fade
- **Duration**: 350ms
- **Easing**: Cubic bezier

---

## Platform Considerations

### Android
- Material Design 3 components
- Ripple effects on taps
- Elevation for depth

### iOS
- Cupertino-style dialogs option
- Haptic feedback on interactions
- Smooth scrolling

### Web
- Hover states for links
- Cursor changes appropriately
- Keyboard shortcuts support
