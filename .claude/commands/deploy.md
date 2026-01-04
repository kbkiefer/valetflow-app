---
description: Build and deploy ValetFlow to a connected iOS device
---

# Deploy ValetFlow to Device

Build and install the ValetFlow app on a connected iOS device.

**Scheme:** ValetFlow
**Configuration:** Debug
**Target:** Connected iOS device

## Steps

1. Check for connected iOS devices
2. If no device found, prompt user to connect device and trust computer
3. Verify device compatibility (iOS 18.2+)
4. Build the ValetFlow scheme for the device
5. Install the app on the device
6. Launch the app (optional)
7. Report deployment results

## Success Criteria

- Build completes successfully
- App installs on device without errors
- App launches and runs properly

## Notes

- Device must be trusted and unlocked
- Code signing must be properly configured
- First deployment may require user approval on device
- Requires Apple Developer account for device deployment

## Troubleshooting

- **No devices found:** Ensure device is connected and unlocked
- **Code signing error:** Check provisioning profile configuration
- **Install failed:** Verify device has enough storage
- **Launch failed:** Check for app crashes in device logs
