# Parameter Logger UI Changes

## 1. Tank Management Screen - Updated 3-Dot Menu

The tank card's 3-dot menu (⋮) now includes a new "Parameter Logger" option:

```
Tank Card
├── Edit (pencil icon)
├── Parameter Logger (science beaker icon) ← NEW
├── Set Card Background (wallpaper icon)
├── Change Icon (emoji icon)
├── Reset Background (restore icon)
├── Get Stocking Ideas (sparkle icon)
├── Duplicate (copy icon)
└── Delete (trash icon)
```

**Visual Styling:**
- Icon: `Icons.science` in teal color
- Text: "Parameter Logger" in teal color
- Positioned second in the menu (right after Edit)

## 2. Parameter Logger Screen (New)

### Empty State
When no parameters have been logged yet:

```
┌─────────────────────────────────────┐
│  [Tank Name] - Parameters           │
│                                 [+] │
├─────────────────────────────────────┤
│                                     │
│         💧 (Water drop icon)        │
│                                     │
│    No Parameters Logged Yet         │
│                                     │
│  Start tracking your water          │
│  parameters to monitor your         │
│  aquarium's health over time.       │
│                                     │
│     [ Add First Reading ]           │
│                                     │
└─────────────────────────────────────┘
                [+] Add Reading (FAB)
```

### With Parameters
When parameters have been logged:

```
┌─────────────────────────────────────┐
│  [Tank Name] - Parameters           │
│                                 [+] │
├─────────────────────────────────────┤
│  Water Parameter History            │
│  Track your aquarium's water        │
│  quality over time                  │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ ⚠️  Ammonia         3 readings│ │
│  │                            ▼  │ │
│  ├───────────────────────────────┤ │
│  │ 🔬 Nitrite          2 readings│ │
│  │                            ▼  │ │
│  ├───────────────────────────────┤ │
│  │ 📊 Nitrate          5 readings│ │
│  │                            ▲  │ │
│  │ ├─ 10.0ppm                   │ │
│  │ │  Jan 15, 2024 - 2:30 PM   │ │
│  │ │  "After water change"  [×]│ │
│  │ ├─ 15.0ppm                   │ │
│  │ │  Jan 10, 2024 - 10:00 AM  │ │
│  │ │                        [×]│ │
│  │ └─ 20.0ppm                   │ │
│  │    Jan 5, 2024 - 9:00 AM    │ │
│  │                        [×]│ │
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
                [+] Add Reading (FAB)
```

### Color Coding
Each parameter type has a distinct color:
- **Ammonia**: Amber/Yellow (⚠️)
- **Nitrite**: Orange (🔬)
- **Nitrate**: Red (📊)
- **Phosphate**: Purple (🫧)
- **Salinity**: Blue (💧)

## 3. Add Parameter Sheet (Bottom Modal)

```
┌─────────────────────────────────────┐
│  Add Parameter Reading          [×] │
├─────────────────────────────────────┤
│                                     │
│  Parameter Type:                    │
│  ┌─────────────────────────────┐   │
│  │ Ammonia              ▼      │   │
│  └─────────────────────────────┘   │
│                                     │
│  Value:              Unit:          │
│  ┌───────────┐     ┌────────┐      │
│  │ 0.5       │     │ ppm ▼  │      │
│  └───────────┘     └────────┘      │
│                                     │
│  Date & Time:                       │
│  ┌─────────────────────────────┐   │
│  │ Jan 15, 2024 - 2:30 PM  📅│   │
│  └─────────────────────────────┘   │
│                                     │
│  Notes (Optional):                  │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │  After 50% water change     │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │      Save Reading           │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

### Form Features:
- **Dropdown**: Select parameter type (5 options)
- **Split input**: Value field + Unit dropdown
- **Date picker**: Combined date and time selection
- **Text area**: Optional notes field (multiline)
- **Full-width button**: Save action

## Navigation Flow

```
Tank Management Screen
        │
        ├─> Click 3-dot menu on tank card
        │
        ├─> Select "Parameter Logger"
        │
        ├─> Parameter Logger Screen
        │
        ├─> Click [+] or "Add Reading" button
        │
        └─> Add Parameter Sheet (modal)
            │
            ├─> Fill in parameter details
            │
            ├─> Click "Save Reading"
            │
            └─> Returns to Parameter Logger Screen
                (with new reading displayed)
```

## Responsive Design Notes

- All screens use Material Design 3 components
- Color scheme follows app theme (light/dark mode support)
- Proper padding and spacing for mobile devices
- Scrollable content areas
- Keyboard-aware input handling
- Modal bottom sheet for add form (doesn't cover entire screen)
