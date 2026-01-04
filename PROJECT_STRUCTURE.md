# ValetFlow Project Structure

## Current Structure
```
ValetFlow App/
└── ValetFlow/
    ├── ValetFlow.xcodeproj
    └── ValetFlow/              (single app)
        ├── ValetFlowApp.swift
        ├── ContentView.swift
        └── Assets.xcassets
```

## Target Structure (Multi-App)
```
ValetFlow App/
└── ValetFlow/
    ├── ValetFlow.xcworkspace   (NEW - workspace for all targets)
    ├── ValetFlow.xcodeproj
    ├── Shared/                  (NEW - shared code framework)
    │   ├── Models/
    │   │   ├── User.swift
    │   │   ├── Employee.swift
    │   │   ├── Community.swift
    │   │   ├── Route.swift
    │   │   ├── Shift.swift
    │   │   ├── Pickup.swift
    │   │   └── Issue.swift
    │   ├── Services/
    │   │   ├── FirebaseService.swift
    │   │   ├── AuthService.swift
    │   │   ├── LocationService.swift
    │   │   └── NotificationService.swift
    │   ├── Utilities/
    │   │   ├── Extensions.swift
    │   │   ├── Constants.swift
    │   │   └── Helpers.swift
    │   └── Views/
    │       └── CommonComponents/
    ├── AdminApp/                (NEW - Manager/Office app)
    │   ├── AdminApp.swift
    │   ├── Views/
    │   │   ├── Dashboard/
    │   │   ├── Employees/
    │   │   ├── Communities/
    │   │   ├── Routes/
    │   │   ├── LiveTracking/
    │   │   └── Reports/
    │   └── Assets.xcassets
    ├── FieldApp/                (NEW - Employee/Driver app)
    │   ├── FieldApp.swift
    │   ├── Views/
    │   │   ├── ClockIn/
    │   │   ├── Route/
    │   │   ├── Pickup/
    │   │   ├── Issues/
    │   │   └── Schedule/
    │   └── Assets.xcassets
    └── CommunityApp/            (NEW - Resident app)
        ├── CommunityApp.swift
        ├── Views/
        │   ├── Schedule/
        │   ├── DriverTracking/
        │   ├── Issues/
        │   └── Account/
        └── Assets.xcassets
```

## Xcode Targets

### 1. **Shared** (Framework)
- **Type:** iOS Framework
- **Bundle ID:** com.valetflow.shared
- **Purpose:** Common code, models, Firebase integration
- **Dependencies:** Firebase SDK

### 2. **ValetFlow Admin** (App)
- **Type:** iOS App
- **Bundle ID:** com.valetflow.admin
- **Display Name:** ValetFlow Admin
- **Purpose:** Management and office operations
- **Dependencies:** Shared framework
- **Deployment:** iOS 18.2+, iPhone & iPad

### 3. **ValetFlow Field** (App)
- **Type:** iOS App
- **Bundle ID:** com.valetflow.field
- **Display Name:** ValetFlow Field
- **Purpose:** Employee/driver operations
- **Dependencies:** Shared framework
- **Deployment:** iOS 18.2+, iPhone only
- **Capabilities:** Background location, push notifications

### 4. **ValetFlow Community** (App)
- **Type:** iOS App
- **Bundle ID:** com.valetflow.community
- **Display Name:** ValetFlow
- **Purpose:** Resident/property manager app
- **Dependencies:** Shared framework
- **Deployment:** iOS 18.2+, iPhone & iPad

## Build Schemes

- **Admin** - Builds and runs AdminApp
- **Field** - Builds and runs FieldApp
- **Community** - Builds and runs CommunityApp
- **All Apps** - Builds all three apps

## Firebase Configuration

Each app target needs its own `GoogleService-Info.plist`:
- `AdminApp/GoogleService-Info.plist`
- `FieldApp/GoogleService-Info.plist`
- `CommunityApp/GoogleService-Info.plist`

All three will point to the same Firebase project but different iOS apps.

## Swift Package Manager Dependencies

All added to Shared framework:
- Firebase/Auth
- Firebase/Firestore
- Firebase/Storage
- Firebase/Messaging (push notifications)
- Firebase/Functions

## Development Workflow

1. Make changes to Shared framework for common functionality
2. Work on individual app targets for app-specific features
3. All apps automatically get Shared updates
4. Build and test each app independently

## Color Scheme & Branding

### Admin App
- Primary: Blue (#007AFF)
- Accent: Dark Gray
- Theme: Professional, data-focused

### Field App
- Primary: Green (#34C759)
- Accent: Orange (for alerts)
- Theme: High contrast, large tap targets

### Community App
- Primary: Teal (#5AC8FA)
- Accent: Purple
- Theme: Clean, friendly, simple
