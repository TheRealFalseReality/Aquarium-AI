# Welcome Screen - Visual Changes Guide

## Layout Structure (Top to Bottom)

```
┌─────────────────────────────────────────────────────────────┐
│                     AQUARIUM AI HEADER                      │
│                   🐠 Aquarium AI Logo 🐠                     │
│         Your intelligent assistant for all things aquatic   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   ⭐ MY TANKS SECTION ⭐                     │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ 🏠 My Tanks                                    →    │  │
│  │    [Tank Count]                                     │  │
│  │ ─────────────────────────────────────────────────── │  │
│  │                                                      │  │
│  │ [When NO tanks:]                                    │  │
│  │ • Description of tank management features           │  │
│  │ • [Create Your First Tank] Button                   │  │
│  │                                                      │  │
│  │ [When tanks EXIST:]                                 │  │
│  │ • Tank Name & Type (Freshwater/Saltwater)          │  │
│  │ • Tank Size (50 gal)                                │  │
│  │ • 🐠 3 species  ✓ Excellent 92%                    │  │
│  │ • Tank notes preview...                             │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              FEATURE CARDS (Staggered Grid)                 │
│                                                              │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐       │
│  │ 🐠 AI Compat │ │ 🤖 AI Chat   │ │ 📷 Photo     │       │
│  │   Tool    →  │ │   bot     →  │ │   Analyzer → │       │
│  │ Description  │ │ Description  │ │ Description  │       │
│  └──────────────┘ └──────────────┘ └──────────────┘       │
│                                                              │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐       │
│  │ 🦐 Stocking  │ │ 🧪 Calculat  │ │ 📏 Volume    │       │
│  │   Assistant→ │ │   ors     →  │ │   Calc    →  │       │
│  │ Description  │ │ Description  │ │ Description  │       │
│  └──────────────┘ └──────────────┘ └──────────────┘       │
│                                                              │
│  ┌──────────────┐                                          │
│  │ 🛒 AquaPi    │                                          │
│  │   Store   →  │                                          │
│  │ Description  │                                          │
│  └──────────────┘                                          │
└─────────────────────────────────────────────────────────────┘
```

## Color Scheme

### My Tanks Section
- **Background**: Primary container with gradient overlay
- **Border**: Primary color with 50% opacity, 2px width
- **Text**: On-primary-container color
- **Icon Background**: Primary color at 20% opacity
- **Elevated appearance**: 5 elevation (Material You) or 3 (standard)

### Harmony Score Badge
```
┌────────────────────────────────┐
│ Excellent (≥80%): Green        │
│ ✓ Excellent 92%                │
│ [Green badge with border]      │
└────────────────────────────────┘

┌────────────────────────────────┐
│ Good (60-79%): Yellow          │
│ ℹ Good 75%                     │
│ [Yellow badge with border]     │
└────────────────────────────────┘

┌────────────────────────────────┐
│ Caution (40-59%): Orange       │
│ ⚠ Caution 55%                  │
│ [Orange badge with border]     │
└────────────────────────────────┘

┌────────────────────────────────┐
│ Poor (<40%): Red               │
│ ⚠ Poor 30%                     │
│ [Red badge with border]        │
└────────────────────────────────┘
```

### Feature Cards
- **Background**: Surface container high (Material You) or default
- **Border**: Outline variant at 30% opacity, 1px
- **Elevation**: 2 (Material You) or 1 (standard)
- **Padding**: 20px all around
- **Spacing**: 16px between cards

## Typography

### My Tanks Section
- **Title**: Headline Small, Bold, On-primary-container color
- **Subtitle**: Body Medium, On-primary-container at 80% opacity
- **Tank Name**: Title Large, Bold, On-primary-container color
- **Tank Type**: Body Small, On-primary-container at 70% opacity
- **Description**: Body Medium, On-primary-container at 90% opacity, 1.5 line height

### Feature Cards
- **Icon**: 32px emoji
- **Title**: Title Medium, Bold
- **Description**: Body Small, On-surface-variant color, 1.4 line height
- **Arrow**: 16px icon, On-surface-variant color

## Responsive Breakpoints

### Large Screens (>1200px)
- 3-column grid for feature cards
- Full-width My Tanks section
- Maximum content width maintained

### Medium Screens (800-1200px)
- 2-column grid for feature cards
- Full-width My Tanks section
- Adjusted padding

### Small Screens (<800px)
- 1-column grid for feature cards
- Full-width My Tanks section
- Optimized for mobile

## Animation Timing

```
Header Animation:     300ms delay
Subtitle:            520ms delay
My Tanks Section:    600ms delay
Feature Card 1:      650ms delay
Feature Card 2:      700ms delay
Feature Card 3:      750ms delay
Feature Card 4:      800ms delay
Feature Card 5:      850ms delay
Feature Card 6:      900ms delay
Feature Card 7:      950ms delay
```

- All animations: 480ms duration
- Easing: Default Material motion
- Opacity: 0 → 1
- Transform: translateY(20) → translateY(0)

## Interaction States

### My Tanks Card
- **Idle**: Normal appearance
- **Hover**: Subtle highlight (web)
- **Pressed**: Splash effect with primary color at 15% opacity
- **Tap**: Navigates to `/tank-management`

### Feature Cards
- **Idle**: Normal appearance
- **Hover**: Subtle highlight (web)
- **Pressed**: Splash effect with primary color at 10% opacity
- **Tap**: Navigates to respective feature route

## Accessibility Features

1. **Semantic Structure**: Proper widget hierarchy
2. **Color Contrast**: 
   - Text on backgrounds meets WCAG AA standards
   - Harmony score badges have sufficient contrast
3. **Touch Targets**: 
   - Minimum 48x48 logical pixels
   - Adequate spacing between interactive elements
4. **Icon + Text**: 
   - Icons paired with text labels
   - Not relying solely on color for meaning

## Key Visual Improvements

1. **Focus on User Content**: My Tanks is now the star
2. **Hierarchy**: Clear visual hierarchy with prominent card at top
3. **Density**: More compact feature cards allow seeing more at once
4. **Modern**: Material You design with gradients and subtle effects
5. **Informative**: Harmony score provides instant feedback
6. **Actionable**: Clear CTAs for empty and filled states
7. **Responsive**: Works beautifully on all screen sizes
8. **Polished**: Smooth animations and transitions
