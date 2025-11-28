# Auto-Update Implementation Plan

## Overview
Implement automatic update functionality using **Sparkle 2.x** - the de-facto standard for macOS app auto-updates. Sparkle handles version checking, downloading, verification, and installation.

## Prerequisites
- App must be code-signed (you have `DEVELOPMENT_TEAM = R63NKJ3TTN` set ✅)
- App is not sandboxed (✅ - allows Sparkle to work without restrictions)
- Need a place to host the appcast XML (GitHub Releases recommended)

---

## Implementation Steps

### 1. Add Sparkle via Swift Package Manager
- Open Xcode project
- File → Add Package Dependencies
- Add `https://github.com/sparkle-project/Sparkle`
- Select version `2.x` (latest stable)
- Add `Sparkle` framework to the main target

### 2. Configure Info.plist
Add the following keys to `Info.plist`:
```xml
<key>SUFeedURL</key>
<string>https://raw.githubusercontent.com/YOUR_USERNAME/Dropnote/main/appcast.xml</string>
<key>SUPublicEDKey</key>
<string>YOUR_ED25519_PUBLIC_KEY</string>
```

### 3. Generate EdDSA Keys for Update Signing
Run in terminal (after Sparkle is added):
```bash
# Find generate_keys in DerivedData or use:
xcrun --find generate_keys
# Or download from Sparkle releases
./generate_keys
```
- Store private key securely (needed for signing releases)
- Add public key to `Info.plist` as `SUPublicEDKey`

### 4. Create UpdateManager Service
Create `Dropnote/Services/UpdateManager.swift`:
- Import Sparkle's `SPUStandardUpdaterController`
- Initialize updater controller on app launch
- Expose methods: `checkForUpdates()`, `automaticallyChecksForUpdates` binding
- Handle updater delegate for customization if needed

### 5. Update AppDelegate
In `DropnoteApp.swift`:
- Initialize `UpdateManager` at app launch
- Keep reference to prevent deallocation

### 6. Add Update Settings to SettingsView
Add new section in `SettingsView.swift`:
- "Check for Updates Automatically" toggle
- "Check for Updates Now" button
- Display current version number

### 7. Add Network Entitlement
Update `Dropnote.entitlements`:
```xml
<key>com.apple.security.network.client</key>
<true/>
```
(Note: Since sandbox is disabled, this may not be strictly required but is good practice)

### 8. Create Appcast XML File
Create `appcast.xml` in repository root:
```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Dropnote Updates</title>
    <item>
      <title>Version X.X</title>
      <sparkle:version>BUILD_NUMBER</sparkle:version>
      <sparkle:shortVersionString>X.X</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <pubDate>DATE</pubDate>
      <enclosure url="DOWNLOAD_URL" 
                 sparkle:edSignature="SIGNATURE"
                 length="FILE_SIZE"
                 type="application/octet-stream"/>
    </item>
  </channel>
</rss>
```

### 9. Create Release Signing Script
Create `scripts/sign_update.sh`:
- Script to sign `.zip` or `.dmg` with EdDSA private key
- Generate signature for appcast
- Can use Sparkle's `sign_update` tool

### 10. Document Release Process
Update `README.md` or create `RELEASING.md`:
1. Bump version in Xcode (MARKETING_VERSION and CURRENT_PROJECT_VERSION)
2. Archive and export app
3. Create `.zip` of the `.app` bundle
4. Sign with `sign_update` tool
5. Upload to GitHub Releases
6. Update `appcast.xml` with new version info
7. Commit and push appcast

---

## File Changes Summary

| File | Action |
|------|--------|
| `Dropnote.xcodeproj/project.pbxproj` | Add Sparkle package dependency |
| `Dropnote/Info.plist` | Add `SUFeedURL`, `SUPublicEDKey` |
| `Dropnote/Dropnote.entitlements` | Add network client entitlement |
| `Dropnote/Services/UpdateManager.swift` | **NEW** - Sparkle controller wrapper |
| `Dropnote/DropnoteApp.swift` | Initialize UpdateManager |
| `Dropnote/Views/SettingsView.swift` | Add Updates section |
| `appcast.xml` | **NEW** - Update feed |
| `scripts/sign_update.sh` | **NEW** - Release signing helper |

---

## Optional Enhancements (Future)

- [ ] Add release notes display in update dialog
- [ ] Add "Skip this version" functionality (built into Sparkle)
- [ ] Add update badge on menu bar icon when update available
- [ ] Automate appcast generation with GitHub Actions
- [ ] Delta updates for faster downloads (Sparkle supports this)

---

## Testing Checklist

- [ ] App checks for updates on launch (if enabled)
- [ ] Manual "Check for Updates" works
- [ ] Toggle for automatic checks persists
- [ ] Update downloads and installs correctly
- [ ] App relaunches after update
- [ ] EdDSA signature verification works
- [ ] Handles "no updates available" gracefully
- [ ] Handles network errors gracefully

