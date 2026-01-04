---
description: Build the ValetFlow app for iOS Simulator
---

# Build ValetFlow for Simulator

Build the ValetFlow project for iOS Simulator with the following configuration:

**Scheme:** ValetFlow
**Configuration:** Debug
**Target:** iOS Simulator (latest available iPhone)
**OS:** Latest iOS version

## Steps

1. Use XcodeBuildMCP to discover available simulators
2. Select an appropriate iPhone simulator (prefer iPhone 17 Pro Max or latest)
3. Boot the simulator if not already running
4. Build the ValetFlow scheme for the selected simulator
5. Report build results (success/failure with relevant details)
6. If build fails, display error messages and suggest fixes

## Success Criteria

- Build completes without errors
- No critical warnings
- App binary is generated successfully

## Notes

- This command uses incremental builds for faster compilation
- Simulator will be booted automatically if needed
- Build logs will show any warnings or errors
