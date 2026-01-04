---
description: Clean build artifacts and derived data for ValetFlow
---

# Clean ValetFlow Build Artifacts

Remove build artifacts, derived data, and cached files to ensure a fresh build.

**Target:** ValetFlow project

## Steps

1. Clean the build folder using xcodebuild clean
2. Optionally remove derived data directory
3. Remove simulator app data (if requested)
4. Report what was cleaned and disk space recovered

## What Gets Cleaned

- Build products (Debug/Release)
- Intermediate build files
- Precompiled headers
- Module cache
- Derived data (optional)

## Success Criteria

- Build folder is cleaned
- No build artifacts remain
- Next build will be a fresh compilation

## Notes

- Clean builds take longer but resolve many build issues
- Incremental build data is lost
- Simulator app data persists unless explicitly removed
- Derived data removal requires additional confirmation

## When to Clean

- Build errors that don't make sense
- After major Xcode or OS updates
- When switching between branches with different dependencies
- To free up disk space
- Before creating a release build
