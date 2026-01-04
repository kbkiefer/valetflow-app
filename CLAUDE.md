# ValetFlow iOS App

## Project Overview

ValetFlow is a modern iOS application built with SwiftUI and Swift 6.0, targeting iOS 18.2+.

## Project Structure

```
ValetFlow App/
├── ValetFlow.xcodeproj/       # Xcode project configuration
├── ValetFlow/                  # Main app source code
│   ├── ValetFlowApp.swift     # App entry point
│   ├── ContentView.swift      # Main content view
│   ├── Assets.xcassets/       # App assets and images
│   └── Preview Content/       # Preview assets for SwiftUI previews
└── .claude/                   # Claude Code configuration
    ├── commands/              # Custom slash commands
    ├── hooks/                 # Automation hooks
    ├── scripts/              # Helper scripts
    └── imports/              # Imported context files
```

## Build Configuration

**Target:** ValetFlow
**Product Bundle Identifier:** com.valetflow.ValetFlow
**Minimum Deployment:** iOS 18.2
**Swift Version:** 6.0
**Supported Devices:** iPhone and iPad

## XcodeBuildMCP Integration

This project uses XcodeBuildMCP for AI-assisted iOS development with Claude Code.

### Essential Workflow

When working with builds, **always specify** the scheme, device, and OS upfront to prevent build errors:

```
Build and run using scheme ValetFlow on iPhone 17 Pro Max with the latest OS
```

### Available MCP Tools

- **Project Discovery:** Analyze project structure and dependencies
- **Simulator Management:** List, boot, and manage iOS simulators
- **Device Management:** Build and deploy to physical devices
- **Session Management:** Track build sessions and configurations

### Incremental Builds

Incremental builds are enabled via `INCREMENTAL_BUILDS_ENABLED=true` for faster compilation cycles.

## Development Guidelines

### Code Style
- Use Swift 6.0 features and strict concurrency checking
- Follow SwiftUI best practices for view composition
- Prefer value types (structs) over reference types (classes)
- Use clear, descriptive naming

### Architecture
- MVVM pattern for complex views
- SwiftUI for all UI components
- Combine for reactive programming when needed

### Testing
- Write unit tests for business logic
- Use SwiftUI previews for UI iteration
- Test on multiple device sizes

## Custom Commands

Use custom slash commands defined in `.claude/commands/`:

- `/build` - Build the project for simulator
- `/test` - Run unit tests
- `/deploy` - Deploy to device
- `/clean` - Clean build artifacts

## Git Workflow

- Main branch: `main`
- Feature branches: `feature/description`
- Commit messages: Follow conventional commits format

## Dependencies

Currently no external dependencies. Add Swift Package Manager dependencies as needed.

## Notes for Claude Code

- This is a greenfield project, ready for feature development
- Use XcodeBuildMCP tools for all build operations
- Always verify builds on simulator before suggesting completion
- Follow iOS Human Interface Guidelines for UI/UX decisions
