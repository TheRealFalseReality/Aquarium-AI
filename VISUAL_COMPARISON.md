# AI Stocking Button - Visual Comparison

## BEFORE: Inline Button in Tank Card

```
┌────────────────────────────────────────────────────────┐
│  🐟 My Community Tank                           [⋮]   │
│  Freshwater                                            │
│                                                        │
│  📏 Size: 55 gal  |  🎯 Harmony: 85%                   │
│                                                        │
│  🐟 Inhabitants (12, 4 types)                         │
│  • 5x Neon Tetra                                      │
│  • 3x Guppy                                           │
│  • 2x Corydoras                                       │
│  • 2x Angelfish                                       │
│                                                        │
│  📷 Tank Photos (3)                                   │
│  [img] [img] [img]                                    │
│                                                        │
│  📝 Notes: Beautiful community tank with...           │
│                                                        │
│  ┌────────────────────────────────────────────────┐  │
│  │ ✨ AI Stocking Recommendations                 │  │ ← OLD BUTTON
│  └────────────────────────────────────────────────┘  │
│                                                        │
│  Created 2024-01-15                                   │
└────────────────────────────────────────────────────────┘
```

**Issues with old design:**
- Takes up significant space in the card
- Repeated on every tank card with inhabitants
- Text label makes button large
- Inline placement reduces card compactness

---

## AFTER: Floating Action Button (FAB)

```
┌────────────────────────────────────────────────────────┐
│  My Tanks                                       [≡]    │
├────────────────────────────────────────────────────────┤
│                                                        │
│  ┌──────────────────────────────────────────────────┐ │
│  │  🐟 My Community Tank                      [⋮]   │ │
│  │  Freshwater                                      │ │
│  │                                                  │ │
│  │  📏 Size: 55 gal  |  🎯 Harmony: 85%             │ │
│  │                                                  │ │
│  │  🐟 Inhabitants (12, 4 types)                   │ │
│  │  • 5x Neon Tetra                                │ │
│  │  • 3x Guppy                                     │ │
│  │  • 2x Corydoras                                 │ │
│  │  • 2x Angelfish                                 │ │
│  │                                                  │ │
│  │  📷 Tank Photos (3)                             │ │
│  │  [img] [img] [img]                              │ │
│  │                                                  │ │
│  │  📝 Notes: Beautiful community tank with...     │ │
│  │                                                  │ │  ← More compact!
│  │  Created 2024-01-15                             │ │
│  └──────────────────────────────────────────────────┘ │
│                                                        │
│  ┌──────────────────────────────────────────────────┐ │
│  │  🐟 Reef Tank                              [⋮]   │ │
│  │  Saltwater                                       │ │
│  │  ...                                             │ │
│  └──────────────────────────────────────────────────┘ │
│                                                        │
│                                                        │
│                                                   ┌──┐ │
│                                                   │✨│ │ ← NEW FAB!
│                                                   └──┘ │
│                               [+ Create Tank]          │
└────────────────────────────────────────────────────────┘
```

**Benefits of new design:**
- **Compact cards**: Removed ~50 pixels from each card height
- **Single button**: One FAB for all tanks (appears when any tank has inhabitants)
- **Icon-only**: Clean, minimalist design
- **Standard position**: Bottom right corner (Material Design standard)
- **Always accessible**: Doesn't scroll away with content
- **Visual hierarchy**: Floating design makes it more discoverable

---

## FAB Details

### Size & Position
```
┌─────────────────────────────────┐
│                                 │
│                                 │
│                                 │
│                                 │
│                            ┌──┐ │ ← 16px from right
│                            │✨│ │
│                            └──┘ │
│                             ↑   │
│                        16px from bottom
└─────────────────────────────────┘

FAB Dimensions: 56px × 56px
Border Radius: 16px
```

### Gradient & Colors
```
┌──────────────────────┐
│ ╔════════════════╗   │
│ ║ 🟣 Purple      ║   │  Colors.purple.shade400 (#AB47BC)
│ ║   ↘            ║   │
│ ║     🔵 Blue    ║   │  Colors.blue.shade500 (#2196F3)
│ ║       ↘        ║   │
│ ║         🔷 Cyan║   │  Colors.cyan.shade400 (#26C6DA)
│ ╚════════════════╝   │
│      Gradient        │
└──────────────────────┘

Direction: Top-Left → Bottom-Right
```

### Icon
```
┌──────────────┐
│              │
│      ✨      │  Icon: Icons.auto_awesome
│              │  Size: 28px
│              │  Color: White
└──────────────┘
```

### Shadow
```
┌──────────────┐
│   ┌────┐     │
│   │ ✨ │     │
│   └────┘     │
│    ╲  ╲      │  Purple shadow
│     ╲  ╲     │  Opacity: 40%
│      ╲  ╲    │  Blur: 12px
│       └──┘   │  Offset: (0, 4px)
└──────────────┘
```

---

## User Interaction Flow

### Before
1. User scrolls through tanks
2. User finds tank with inhabitants
3. User clicks large button in card
4. AI recommendations shown

### After
1. User scrolls through tanks
2. User sees floating FAB in bottom right (if any tank has inhabitants)
3. User clicks compact FAB
4. AI recommendations shown for first tank with inhabitants

**Alternative**: User can still access via three-dot menu → "Get Stocking Ideas"

---

## Accessibility

- **Touch Target**: 56×56px exceeds minimum 48×48px requirement
- **Visual Feedback**: InkWell ripple effect on tap
- **Color Contrast**: White icon on gradient background provides excellent contrast
- **Discoverability**: Floating position and unique gradient make it stand out
- **Alternative Access**: Menu option preserved for users who prefer it
