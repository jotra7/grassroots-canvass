# iOS Build & App Store Guide

Complete guide to building and publishing Grassroots Canvass for iOS.

---

## Prerequisites

- Mac computer (required for iOS builds)
- Xcode 15+ (free from Mac App Store)
- Flutter SDK 3.10+
- Apple Developer account ($99/year)
- CocoaPods installed (`sudo gem install cocoapods`)

---

## Quick Build

```bash
cd flutter-app
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release
```

Then open in Xcode and archive.

---

## Step-by-Step Setup

### 1. Install Dependencies

```bash
cd flutter-app
flutter pub get
cd ios
pod install
cd ..
```

### 2. Open in Xcode

```bash
open ios/Runner.xcworkspace
```

**Important:** Open the `.xcworkspace` file, NOT the `.xcodeproj`.

### 3. Configure Signing

In Xcode:

1. Select **Runner** in the project navigator
2. Select **Runner** target
3. Go to **Signing & Capabilities** tab
4. Check **Automatically manage signing**
5. Select your Team (Apple Developer account)
6. Xcode will create provisioning profiles automatically

### 4. Update Bundle Identifier

1. In Xcode, select **Runner** target
2. Go to **General** tab
3. Change **Bundle Identifier** to: `com.yourcampaign.canvass`

Also update in `ios/Runner/Info.plist` if needed.

### 5. Update App Name

Edit `ios/Runner/Info.plist`:

```xml
<key>CFBundleDisplayName</key>
<string>Grassroots Canvass</string>
<key>CFBundleName</key>
<string>Grassroots Canvass</string>
```

### 6. Update Version Numbers

In Xcode → Runner target → General:
- **Version**: 1.0.0 (user-visible)
- **Build**: 1 (increment for each upload)

Or in `pubspec.yaml`:
```yaml
version: 1.0.0+1  # version+build
```

### 7. Configure Permissions

Edit `ios/Runner/Info.plist` with specific descriptions:

```xml
<!-- Location - REQUIRED for map features -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app uses your location to show nearby voters on the map and optimize walking routes for door-to-door canvassing.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app uses your location to show nearby voters on the map and optimize walking routes for door-to-door canvassing.</string>

<!-- Microphone - for voice notes -->
<key>NSMicrophoneUsageDescription</key>
<string>This app uses the microphone to record voice notes about voter conversations.</string>

<!-- Camera - if using for any feature -->
<key>NSCameraUsageDescription</key>
<string>This app may use the camera to scan QR codes or capture images.</string>

<!-- Contacts - if importing contacts -->
<key>NSContactsUsageDescription</key>
<string>This app can access contacts to quickly add phone numbers.</string>
```

**CRITICAL:** Apple will reject your app if permission descriptions are vague. Be specific about WHY you need each permission.

### 8. Update App Icon

Replace icons in:
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

Required sizes:
- 20x20, 29x29, 40x40, 58x58, 60x60, 76x76, 80x80, 87x87
- 120x120, 152x152, 167x167, 180x180, 1024x1024

Or use flutter_launcher_icons package (see Android README).

### 9. Build for Release

```bash
flutter build ios --release
```

---

## App Store Submission

### 1. Create Apple Developer Account

1. Go to [developer.apple.com/programs](https://developer.apple.com/programs)
2. Click **Enroll**
3. Sign in with Apple ID
4. Pay $99/year
5. Wait 24-48 hours for approval

**For Organizations:**
- Need a D-U-N-S number (free, 1-2 weeks to obtain)
- Apple verifies your organization

### 2. Create App Store Connect Entry

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   - Platform: iOS
   - Name: Grassroots Canvass
   - Primary Language: English
   - Bundle ID: Select your bundle ID
   - SKU: grassroots-canvass (any unique string)

### 3. Complete App Information

**App Information:**
- Subtitle (30 chars): "Voter Canvassing Tool"
- Category: Productivity or Utilities
- Content Rights: You own the rights

**Pricing and Availability:**
- Price: Free
- Availability: All countries (or select specific ones)

### 4. Prepare App Privacy

#### Privacy Policy URL (Required)
Must provide a publicly accessible URL with your privacy policy.

#### App Privacy Details

Answer these questions in App Store Connect:

**Data Collected:**

| Data Type | Collected | Linked to User | Used for Tracking |
|-----------|-----------|----------------|-------------------|
| Contact Info | Yes | Yes | No |
| Location (Precise) | Yes | Yes | No |
| User Content | Yes | Yes | No |
| Identifiers | Yes | Yes | No |

**Data Uses:**
- App Functionality: Yes
- Analytics: No (unless you add analytics)
- Advertising: No

### 5. Prepare Screenshots

Required screenshot sizes:

| Device | Size | Required? |
|--------|------|-----------|
| iPhone 6.7" | 1290 x 2796 | Yes |
| iPhone 6.5" | 1284 x 2778 | Yes |
| iPhone 5.5" | 1242 x 2208 | Yes |
| iPad Pro 12.9" | 2048 x 2732 | If supporting iPad |

**Tips:**
- Show main features (map, voter list, contact logging)
- Use real-looking data (not "test" or placeholder text)
- No device frames required (Apple adds them)

### 6. Write App Description

**Description (4000 chars max):**
```
Grassroots Canvass is a voter canvassing app designed for grassroots campaigns and independent candidates.

FEATURES:
• View voters on an interactive map
• Optimized walking routes for door-to-door canvassing
• Log door knocks, phone calls, and text messages
• Record voice notes after conversations
• Works offline - syncs when you're back online
• 28 canvass result options (Supportive, Opposed, Not Home, etc.)

TEAM FEATURES:
• Role-based access (Admin, Team Lead, Canvasser)
• Territory assignment with map-based boundaries
• Real-time sync across your team
• Analytics and progress tracking

Perfect for:
• Independent candidates
• Local campaigns
• Grassroots organizers
• Community outreach

Your data stays private - hosted on your own Supabase database.
```

**Keywords (100 chars):**
```
canvassing,voter,campaign,election,door knock,phone bank,volunteer,grassroots,political
```

**Promotional Text (170 chars):**
```
Free, open-source canvassing tool for grassroots campaigns. Map your territory, track contacts, and organize your team.
```

### 7. Create Demo Account

Apple reviewers need to test your app:

1. Create a test account in your Supabase database
2. Pre-populate with sample data (voters, cut lists)
3. Build the app with demo credentials:
   ```bash
   flutter build ios --release \
     --dart-define=DEMO_EMAIL=your-demo@example.com \
     --dart-define=DEMO_PASSWORD=YourSecurePassword123
   ```
4. Provide the same credentials in App Store Connect review notes

### 8. Archive and Upload

In Xcode:

1. Select **Product** → **Archive**
2. Wait for archive to build
3. In Organizer window, click **Distribute App**
4. Select **App Store Connect** → **Upload**
5. Follow the wizard, accepting defaults
6. Wait for upload to complete

### 9. Submit for Review

In App Store Connect:

1. Select your uploaded build
2. Answer export compliance questions:
   - Uses encryption: Yes (HTTPS)
   - Standard encryption: Yes
3. Complete all required fields
4. Click **Submit for Review**

### 10. Review Process

- First submission: 24-48 hours typically
- Some apps take longer (up to 2 weeks)
- You'll receive email notifications

---

## Common Rejection Reasons

### Guideline 2.1 - App Completeness

**Problem:** App crashes or has bugs during review.

**Solution:**
- Test thoroughly on real devices
- Test the demo account works
- Check all features complete

### Guideline 5.1.1 - Data Collection and Storage

**Problem:** Privacy concerns with voter data.

**Solution:**
- Clear privacy policy
- Explain data is user-provided voter rolls
- Account deletion must work
- Accurate App Privacy labels

### Guideline 5.1.2 - Data Use and Sharing

**Problem:** Vague permission descriptions.

**Solution:**
Update Info.plist with SPECIFIC reasons:
```
BAD: "This app needs your location."
GOOD: "This app uses your location to show nearby voters on the map and optimize walking routes for door-to-door canvassing."
```

### Guideline 4.2 - Minimum Functionality

**Problem:** App seems like a simple wrapper or has limited features.

**Solution:**
- Ensure all features work
- Show the value beyond a simple website
- Highlight offline functionality

### Metadata Rejected

**Problem:** Screenshots or description issues.

**Solution:**
- No placeholder text in screenshots
- Accurate description of features
- No mentions of other platforms ("also on Android")

---

## TestFlight (Beta Testing)

Before App Store submission, use TestFlight:

### Internal Testing (up to 100 testers)

1. Upload a build to App Store Connect
2. Go to **TestFlight** → **Internal Testing**
3. Add testers by email
4. They install via TestFlight app

### External Testing (up to 10,000 testers)

1. Create a test group
2. Add a build for testing
3. Submit for Beta App Review (quick, ~1 day)
4. Share public link or add testers by email

---

## Updating the App

1. Increment build number in Xcode or pubspec.yaml
2. Archive and upload new build
3. In App Store Connect, select new build
4. Add "What's New" text
5. Submit for review

---

## Files to Keep Secret

Never commit:
- Distribution certificates (.p12)
- Provisioning profiles
- Private keys

These are managed by Xcode automatically when using "Automatically manage signing."

---

## Useful Commands

```bash
# Clean build
flutter clean && flutter pub get

# Install pods
cd ios && pod install && cd ..

# Build for release
flutter build ios --release

# Open in Xcode
open ios/Runner.xcworkspace

# List simulators
xcrun simctl list devices

# Run on specific simulator
flutter run -d "iPhone 15 Pro"
```

---

## Troubleshooting

### "No signing certificate"

1. Open Xcode → Preferences → Accounts
2. Add your Apple ID
3. Download certificates
4. Enable "Automatically manage signing"

### "Pod install fails"

```bash
cd ios
pod deintegrate
pod cache clean --all
pod install
```

### "Module not found"

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

### Build succeeds but archive fails

- Check you're building for "Any iOS Device" not a simulator
- Verify signing is configured correctly
- Check all required icons are present
