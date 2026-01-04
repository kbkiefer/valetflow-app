# Xcode Setup Guide - ValetFlow Multi-Target Project

## Overview

You need to configure Xcode to create 4 targets:
1. **Shared** - Framework with common code
2. **ValetFlow Admin** - Management app
3. **ValetFlow Field** - Employee app
4. **ValetFlow Community** - Resident app

## Step 1: Open Xcode

1. Open `/Users/kbkiefer/Documents/ValetFlow App/ValetFlow/ValetFlow.xcodeproj` in Xcode

## Step 2: Delete the Old Target

1. In Project Navigator (left sidebar), select the **ValetFlow** project (top item)
2. In the main editor area, you'll see TARGETS list
3. Select the old **ValetFlow** target
4. Click the **-** (minus) button at the bottom of the targets list
5. Confirm deletion

## Step 3: Create Shared Framework

1. Click **File** → **New** → **Target**
2. Select **iOS** → **Framework**
3. Click **Next**
4. Configure:
   - **Product Name:** Shared
   - **Organization Identifier:** com.valetflow
   - **Bundle Identifier:** com.valetflow.shared
   - **Language:** Swift
5. Click **Finish**
6. **Add Files to Shared Target:**
   - In Project Navigator, select all files in the `Shared/` folder
   - In File Inspector (right sidebar), under **Target Membership**, check **Shared**

## Step 4: Create Admin App Target

1. Click **File** → **New** → **Target**
2. Select **iOS** → **App**
3. Click **Next**
4. Configure:
   - **Product Name:** ValetFlow Admin
   - **Organization Identifier:** com.valetflow
   - **Bundle Identifier:** com.valetflow.admin
   - **Interface:** SwiftUI
   - **Language:** Swift
5. Click **Finish**
6. When prompted "Activate ValetFlow Admin scheme?", click **Activate**
7. **Add Files to Admin Target:**
   - Select all files in `AdminApp/` folder
   - In File Inspector, under **Target Membership**, check **ValetFlow Admin**
   - Make sure **AdminApp.swift** is the @main entry point

## Step 5: Create Field App Target

1. Click **File** → **New** → **Target**
2. Select **iOS** → **App**
3. Click **Next**
4. Configure:
   - **Product Name:** ValetFlow Field
   - **Organization Identifier:** com.valetflow
   - **Bundle Identifier:** com.valetflow.field
   - **Interface:** SwiftUI
   - **Language:** Swift
5. Click **Finish**
6. Click **Activate** when prompted
7. **Add Files to Field Target:**
   - Select all files in `FieldApp/` folder
   - In File Inspector, under **Target Membership**, check **ValetFlow Field**

## Step 6: Create Community App Target

1. Click **File** → **New** → **Target**
2. Select **iOS** → **App**
3. Click **Next**
4. Configure:
   - **Product Name:** ValetFlow
   - **Organization Identifier:** com.valetflow
   - **Bundle Identifier:** com.valetflow.community
   - **Interface:** SwiftUI
   - **Language:** Swift
5. Click **Finish**
6. Click **Activate** when prompted
7. **Add Files to Community Target:**
   - Select all files in `CommunityApp/` folder
   - In File Inspector, under **Target Membership**, check **ValetFlow**

## Step 7: Link Shared Framework to Apps

For **each app target** (Admin, Field, Community):

1. Select the **ValetFlow** project in Project Navigator
2. Select the **app target** (e.g., ValetFlow Admin)
3. Go to **General** tab
4. Scroll to **Frameworks, Libraries, and Embedded Content**
5. Click the **+** button
6. Select **Shared.framework**
7. Make sure **Embed & Sign** is selected
8. Click **Add**

Repeat this for all three app targets.

## Step 8: Add Firebase SDK

1. Select the **ValetFlow** project
2. Click **File** → **Add Package Dependencies**
3. In the search bar, paste: `https://github.com/firebase/firebase-ios-sdk`
4. Select version: **Latest (11.x.x)**
5. Click **Add Package**
6. In the package product selection:
   - For **Shared** target, select:
     - FirebaseAuth
     - FirebaseFirestore
     - FirebaseStorage
     - FirebaseMessaging
   - Click **Add Package**

## Step 9: Configure Info.plist for Location (Field App only)

1. Select **ValetFlow Field** target
2. Go to **Info** tab
3. Add these keys:
   - **Privacy - Location When In Use Usage Description**
     - Value: "We need your location to track your route progress"
   - **Privacy - Location Always Usage Description**
     - Value: "We need background location to track routes even when the app is closed"
   - **Privacy - Location Always and When In Use Usage Description**
     - Value: "We track your location to show route progress to customers"

## Step 10: Enable Background Modes (Field App only)

1. Select **ValetFlow Field** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **Background Modes**
5. Check:
   - **Location updates**
   - **Background fetch**
   - **Remote notifications**

## Step 11: Configure Schemes

Create build schemes for easy switching:

1. Click the scheme selector (top left, next to Run/Stop buttons)
2. Select **Manage Schemes**
3. Make sure these schemes exist and are checked:
   - Shared
   - ValetFlow Admin
   - ValetFlow Field
   - ValetFlow

## Step 12: Test Build Each App

For each app:

1. Select the scheme (Admin/Field/Community)
2. Select a simulator (iPhone 17 Pro Max)
3. Press **⌘ + B** to build
4. Fix any errors (there may be missing imports)

## Common Issues & Fixes

### "No such module 'Firebase'"
- Make sure Firebase packages are added to **Shared** target
- Clean build folder: **Product** → **Clean Build Folder** (⇧⌘K)

### "Cannot find type 'AuthService' in scope"
- Make sure all Shared files have **Shared** target membership
- Make sure each app links to **Shared.framework**

### Build errors in app targets
- Check that @main struct name matches the app (AdminApp, FieldApp, CommunityApp)
- Make sure each app only has ONE @main entry point

## Next Steps

Once all three apps build successfully:
1. Set up Firebase project at https://console.firebase.google.com
2. Download `GoogleService-Info.plist` for each app
3. Add to respective app targets
4. Test authentication flow

## Need Help?

If you encounter issues, let me know which step failed and the exact error message.
