# Parameter Logger Architecture

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Interface Layer                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  TankManagementScreen                                            │
│  ├─ Tank Card List                                               │
│  │  └─ 3-Dot Menu                                                │
│  │     ├─ Edit                                                   │
│  │     ├─ Parameter Logger ← NEW                                 │
│  │     ├─ Set Background                                         │
│  │     └─ ...                                                    │
│  │                                                               │
│  └─ Navigates to ──────────────────────────┐                    │
│                                              ↓                    │
│                              ┌───────────────────────────────┐   │
│                              │  ParameterLoggerScreen        │   │
│                              ├───────────────────────────────┤   │
│                              │ - Empty State                 │   │
│                              │ - Parameter Groups (Expandable)│  │
│                              │ - Floating Action Button      │   │
│                              │                               │   │
│                              │ Opens ─────────────────┐      │   │
│                              │                        ↓      │   │
│                              │        ┌───────────────────┐  │   │
│                              │        │ AddParameterSheet │  │   │
│                              │        ├───────────────────┤  │   │
│                              │        │ - Parameter Type  │  │   │
│                              │        │ - Value & Unit    │  │   │
│                              │        │ - Date & Time     │  │   │
│                              │        │ - Notes           │  │   │
│                              │        │ - Save Button     │  │   │
│                              │        └───────────────────┘  │   │
│                              └───────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      State Management Layer                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  TankProvider (StateNotifier<TankState>)                         │
│  ├─ manages List<Tank>                                           │
│  ├─ addTank()                                                    │
│  ├─ updateTank() ← Used for adding/deleting parameters          │
│  ├─ deleteTank()                                                 │
│  └─ _saveTanks() ← Persists to SharedPreferences                │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                          Data Model Layer                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────┐          ┌──────────────────────┐    │
│  │   Tank               │          │  WaterParameter       │    │
│  ├──────────────────────┤          ├──────────────────────┤    │
│  │ - id                 │          │ - id                 │    │
│  │ - name               │          │ - parameterType      │    │
│  │ - type               │          │ - value              │    │
│  │ - inhabitants        │          │ - unit               │    │
│  │ - sizeGallons        │          │ - dateRecorded       │    │
│  │ - sizeLiters         │          │ - notes              │    │
│  │ - photos             │          │                      │    │
│  │ - waterParameters ◄──┼──────────┤ Methods:             │    │
│  │   (List)             │  has     │ - create()           │    │
│  │ - createdAt          │   many   │ - toJson()           │    │
│  │ - updatedAt          │          │ - fromJson()         │    │
│  │                      │          │ - copyWith()         │    │
│  │ Methods:             │          └──────────────────────┘    │
│  │ - create()           │                                       │
│  │ - toJson()           │                                       │
│  │ - fromJson()         │                                       │
│  │ - copyWith()         │                                       │
│  └──────────────────────┘                                       │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                       Persistence Layer                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  SharedPreferences                                               │
│  ├─ Key: 'user_tanks'                                            │
│  └─ Value: JSON array of Tank objects (including waterParameters)│
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow Diagrams

### Adding a Parameter

```
User Action                 UI Layer                State Layer           Data Layer
    │                          │                        │                    │
    │ 1. Click "Add"           │                        │                    │
    ├────────────────────────► │                        │                    │
    │                          │                        │                    │
    │ 2. Show Modal            │                        │                    │
    │ ◄────────────────────────┤                        │                    │
    │                          │                        │                    │
    │ 3. Fill Form & Save      │                        │                    │
    ├────────────────────────► │                        │                    │
    │                          │                        │                    │
    │                          │ 4. Create WaterParameter│                   │
    │                          ├───────────────────────►│                    │
    │                          │                        │                    │
    │                          │ 5. Update Tank          │                   │
    │                          │    (add parameter)      │                   │
    │                          ├───────────────────────►│                    │
    │                          │                        │                    │
    │                          │                        │ 6. Persist Tank    │
    │                          │                        ├──────────────────► │
    │                          │                        │                    │
    │                          │ 7. UI Updates          │                    │
    │                          │ ◄──────────────────────┤                    │
    │                          │                        │                    │
    │ 8. Close Modal &         │                        │                    │
    │    Show New Parameter    │                        │                    │
    │ ◄────────────────────────┤                        │                    │
    │                          │                        │                    │
```

### Viewing Parameters

```
User Action                 UI Layer                State Layer           Data Layer
    │                          │                        │                    │
    │ 1. Open Parameter Logger │                        │                    │
    ├────────────────────────► │                        │                    │
    │                          │                        │                    │
    │                          │ 2. Read Tank           │                    │
    │                          ├───────────────────────►│                    │
    │                          │                        │                    │
    │                          │ 3. Get waterParameters │                    │
    │                          │ ◄──────────────────────┤                    │
    │                          │                        │                    │
    │                          │ 4. Group & Sort        │                    │
    │                          │    by type & date      │                    │
    │                          │                        │                    │
    │ 5. Display Grouped       │                        │                    │
    │    Parameters            │                        │                    │
    │ ◄────────────────────────┤                        │                    │
    │                          │                        │                    │
    │ 6. Expand/Collapse       │                        │                    │
    │    Groups                │                        │                    │
    ├────────────────────────► │                        │                    │
    │ ◄────────────────────────┤                        │                    │
```

### Deleting a Parameter

```
User Action                 UI Layer                State Layer           Data Layer
    │                          │                        │                    │
    │ 1. Click Delete          │                        │                    │
    ├────────────────────────► │                        │                    │
    │                          │                        │                    │
    │ 2. Show Confirmation     │                        │                    │
    │ ◄────────────────────────┤                        │                    │
    │                          │                        │                    │
    │ 3. Confirm Delete        │                        │                    │
    ├────────────────────────► │                        │                    │
    │                          │                        │                    │
    │                          │ 4. Filter out parameter│                    │
    │                          │    from list           │                    │
    │                          ├───────────────────────►│                    │
    │                          │                        │                    │
    │                          │ 5. Update Tank         │                    │
    │                          │    (remove parameter)  │                    │
    │                          ├───────────────────────►│                    │
    │                          │                        │                    │
    │                          │                        │ 6. Persist Tank    │
    │                          │                        ├──────────────────► │
    │                          │                        │                    │
    │                          │ 7. UI Updates          │                    │
    │                          │ ◄──────────────────────┤                    │
    │                          │                        │                    │
    │ 8. Parameter Removed     │                        │                    │
    │ ◄────────────────────────┤                        │                    │
```

## Component Relationships

```
ParameterLoggerScreen (Consumer Widget)
├── Uses: TankProvider (via ref.read/ref.watch)
├── Receives: Tank object (via constructor)
├── Manages: 
│   ├── Local UI state (_expandedParameter)
│   └── User interactions
└── Contains:
    ├── Parameter List (grouped by type)
    │   └── Parameter Items (sorted by date)
    └── _AddParameterSheet (modal)
        ├── Form validation
        ├── Date picker
        └── Unit selection

WaterParameter Model
├── Independent data class
├── JSON serializable
├── Immutable with copyWith
└── Used by: Tank model

Tank Model  
├── Contains: List<WaterParameter>
├── Manages: JSON serialization with waterParameters
└── Used by: TankProvider for state management

TankProvider
├── Manages: Global tank state
├── Persists: All tanks to SharedPreferences
└── Notifies: All listening widgets on changes
```

## Key Design Decisions

1. **Reuse Existing Infrastructure**
   - Uses existing TankProvider (no new provider needed)
   - Uses existing persistence mechanism
   - Follows existing patterns for screen navigation

2. **Immutable Data Models**
   - WaterParameter is immutable
   - Updates use copyWith pattern
   - Prevents accidental mutations

3. **Color Coding**
   - Each parameter type has distinct color
   - Improves quick visual identification
   - Consistent throughout the UI

4. **Grouping Strategy**
   - Group by parameter type first
   - Sort by date within groups
   - Expandable groups reduce clutter

5. **Backward Compatibility**
   - waterParameters defaults to empty list
   - Existing tanks without parameters continue to work
   - No migration needed

6. **User Experience**
   - Empty state encourages first action
   - Modal bottom sheet for quick parameter entry
   - Confirmation for destructive actions
   - Color coding for quick parameter identification
