# Claude Code Configuration for ValetFlow

## Quick Start

This project is configured with XcodeBuildMCP for streamlined iOS development.

### First Time Setup

1. Ensure XcodeBuildMCP is installed: `claude mcp list`
2. Verify the ValetFlow scheme exists
3. Choose your target simulator or device

### Build Instructions

Always provide complete context when requesting builds:

```
Build and run using scheme ValetFlow on iPhone 17 Pro Max with iOS 18.2
```

## Directory Structure

- **commands/** - Custom slash commands for common operations
- **hooks/** - Automation scripts that run on events
- **scripts/** - Helper utilities for development tasks
- **imports/** - Reusable context files

## Custom Commands

### /build
Builds the ValetFlow app for iOS Simulator using the default configuration.

### /test
Runs the test suite for the ValetFlow project.

### /deploy
Builds and deploys to a connected iOS device.

### /clean
Cleans build artifacts and derived data.

## Hooks

### startup-hook
Runs when Claude Code session starts:
- Verifies Xcode installation
- Checks for simulator availability
- Displays current git branch

### pre-build-hook
Runs before build operations:
- Validates project configuration
- Checks for uncommitted changes (optional warning)

### post-edit-hook
Runs after file edits:
- Formats Swift files using swift-format (if installed)
- Updates documentation if needed

## MCP Tool Usage Patterns

### Discovering Project Info
Use `xcodebuild_project_discovery` to analyze the project structure.

### Simulator Operations
1. List available simulators
2. Boot the target simulator
3. Build for simulator
4. Install and launch app

### Build Sessions
XcodeBuildMCP maintains session context. Specify device and OS once per session.

## Best Practices

1. **Always specify build context** - Include scheme, device, and OS in requests
2. **Use incremental builds** - Enabled by default for faster iterations
3. **Verify before completion** - Always test builds before marking tasks complete
4. **Follow Swift conventions** - Use SwiftLint rules if configured
5. **Test on multiple devices** - Verify iPhone and iPad layouts

## Troubleshooting

### Build Failures
- Check scheme name matches "ValetFlow"
- Verify simulator is booted
- Clean build folder if needed

### Simulator Issues
- List available simulators: use MCP tools
- Boot simulator before building
- Reset simulator if app behaves unexpectedly

### MCP Connection
- Restart Claude Code if MCP tools are unavailable
- Verify `.claude.json` configuration
- Check Node.js version (requires 18.x+)
