# Mobile App Build & Publishing Guide

This guide covers building and publishing the Grassroots Canvass mobile app to the Apple App Store and Google Play Store.

**Important**: Publishing to app stores requires developer accounts and compliance with store policies.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Developer Account Requirements](#developer-account-requirements)
3. [App Store Requirements (Apple)](#app-store-requirements-apple)
4. [Google Play Requirements](#google-play-requirements)
5. [Building the Apps](#building-the-apps)
6. [App Store Submission Checklist](#app-store-submission-checklist)
7. [Common Rejection Reasons](#common-rejection-reasons)
8. [Alternative: Web App Only](#alternative-web-app-only)

---

## Prerequisites

### Developer Accounts (Required for Store Publishing)

| Platform | Cost | Time to Approve |
|----------|------|-----------------|
| Apple Developer Program | $99/year | 24-48 hours |
| Google Play Developer | $25 one-time | 24-48 hours |

### For Building Locally

- **Mac computer** (required for iOS builds)
- **Xcode 15+** (free from Mac App Store)
- **Flutter SDK 3.10+** ([Install guide](https://docs.flutter.dev/get-started/install))
- **Android Studio** (free, for Android builds)

### For Building Without a Mac

Use **Codemagic** (cloud build service):
- Free tier: 500 build minutes/month
- Can build iOS apps without a Mac
- See [Codemagic Setup](#using-codemagic-recommended-for-non-developers)

---

## Developer Account Requirements

### Apple Developer Program ($99/year)

1. Go to [developer.apple.com/programs](https://developer.apple.com/programs)
2. Click **Enroll**
3. Sign in with your Apple ID (or create one)
4. Choose enrollment type:
   - **Individual**: Use your personal name
   - **Organization**: Requires D-U-N-S number (see below)
5. Pay the $99 annual fee
6. Wait 24-48 hours for approval

**For Organizations (Campaigns, PACs, etc.):**
- You need a **D-U-N-S Number** (free, takes 1-2 weeks)
- Apply at [dnb.com/duns-number](https://www.dnb.com/duns-number.html)
- Apple verifies your organization is legitimate

### Google Play Developer ($25 one-time)

1. Go to [play.google.com/console](https://play.google.com/console)
2. Sign in with a Google account
3. Pay the $25 registration fee
4. Complete identity verification (government ID required)
5. Wait 24-48 hours for approval

---

## App Store Requirements (Apple)

Apple has strict requirements. Your app **will be rejected** if you don't meet these.

### Privacy Requirements (CRITICAL)

#### 1. Privacy Policy (Required)

You MUST have a privacy policy URL. It must explain:
- What data you collect (names, addresses, phone numbers, location)
- How you use the data (canvassing, voter contact)
- How you protect the data
- How users can request data deletion

**Free privacy policy generators:**
- [TermsFeed](https://termsfeed.com/privacy-policy/generator/)
- [Iubenda](https://www.iubenda.com)

Host your privacy policy on:
- Your campaign website
- A free GitHub Pages site
- Notion (make the page public)

#### 2. App Privacy Labels

When submitting, you must declare what data your app collects:

| Data Type | Collected? | Usage |
|-----------|------------|-------|
| Contact Info (name, email, phone) | Yes | App Functionality |
| Location (precise) | Yes | App Functionality |
| User Content (notes, voice recordings) | Yes | App Functionality |
| Identifiers (user ID) | Yes | App Functionality |

**Linked to Identity**: Yes (data is linked to user accounts)

#### 3. Location Permission Justification

In `Info.plist`, you must explain why you need location:

```
"This app uses your location to show nearby voters on the map and optimize walking routes for door-to-door canvassing."
```

**Apple will reject vague descriptions** like "for app functionality."

#### 4. Data Deletion Requirement (New in 2024)

Users must be able to:
- Delete their account
- Request deletion of their data

The app includes account deletion in Settings. Make sure it works before submitting.

### Content Requirements

#### 1. App Screenshots
- iPhone 6.5" display (1284 x 2778 px) - Required
- iPhone 5.5" display (1242 x 2208 px) - Required
- iPad Pro 12.9" (2048 x 2732 px) - If supporting iPad

#### 2. App Description
Write a clear description explaining:
- What the app does
- Who it's for (campaign volunteers, canvassers)
- Key features

**Example:**
> Grassroots Canvass is a voter canvassing app for grassroots campaigns and independent candidates. Volunteers can view voter lists on a map, record door-knock results, log phone calls and texts, and sync their work with the campaign team. Features offline mode for areas without cell service.

#### 3. Demo Account (Required for Review)

Apple reviewers need to test your app:

1. Create a test account in your Supabase database
2. Pre-populate with sample voters and cut lists
3. Build the app with demo credentials using `--dart-define` flags:
   ```bash
   flutter build ios --release \
     --dart-define=DEMO_EMAIL=your-demo@example.com \
     --dart-define=DEMO_PASSWORD=YourSecurePassword
   ```
4. Provide the same email/password in App Store Connect review notes

### Age Rating

When submitting, Apple asks about content. For a canvassing app:
- No objectionable content
- Age rating will be: **4+**

### App Review Guidelines

Read Apple's guidelines: [developer.apple.com/app-store/review/guidelines](https://developer.apple.com/app-store/review/guidelines/)

Key sections:
- **1.1 Objectionable Content** - Voter data is not objectionable
- **2.1 App Completeness** - App must be fully functional
- **5.1 Privacy** - Must comply with privacy requirements

---

## Google Play Requirements

Google is generally less strict than Apple, but still has requirements.

### Privacy Requirements

#### 1. Privacy Policy (Required)
Same as Apple - you need a hosted privacy policy URL.

#### 2. Data Safety Section

When submitting, you declare:
- Data collected: Names, phone numbers, location, user-generated content
- Data shared: No (unless you share with third parties)
- Data encrypted in transit: Yes (Supabase uses HTTPS)
- Users can request data deletion: Yes

#### 3. Permissions Declarations

Explain why you need these permissions:
- **Location**: "To display voters on a map and calculate walking routes"
- **Internet**: "To sync data with the campaign database"
- **Storage**: "To cache voter data for offline use"

### Content Rating

Complete the content rating questionnaire. For a canvassing app:
- Violence: None
- Sexual content: None
- Profanity: None
- Controlled substances: None

Rating will be: **Everyone**

### Target Audience

Declare that the app is for:
- Ages 18+ (voter data handling)
- Not designed for children

### Store Listing Assets

Required:
- **App icon**: 512x512 PNG
- **Feature graphic**: 1024x500 PNG
- **Screenshots**: At least 2 phone screenshots
- **Short description**: 80 characters max
- **Full description**: 4000 characters max

---

## Building the Apps

### Configure the App

Before building, update these files with your settings:

#### 1. Supabase Configuration

Edit `flutter-app/lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://YOUR-PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR-ANON-KEY';
}
```

#### 2. App Name and Bundle ID

For iOS, edit `flutter-app/ios/Runner/Info.plist`:
- `CFBundleDisplayName`: Your app name
- `CFBundleName`: Your app name

For Android, edit `flutter-app/android/app/build.gradle.kts`:
- `applicationId`: Your unique bundle ID (e.g., `com.yourcampaign.canvass`)

### Build for iOS

```bash
cd flutter-app
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release
```

Then open in Xcode:
```bash
open ios/Runner.xcworkspace
```

In Xcode:
1. Select **Product** → **Archive**
2. Click **Distribute App**
3. Choose **App Store Connect**
4. Follow the upload wizard

### Build for Android

```bash
cd flutter-app
flutter pub get
flutter build appbundle --release
```

The signed bundle will be at:
`build/app/outputs/bundle/release/app-release.aab`

Upload this to Google Play Console.

### Using Codemagic (Recommended for Non-Developers)

1. Sign up at [codemagic.io](https://codemagic.io)
2. Connect your GitHub account
3. Add your forked repository
4. Create a new Flutter workflow
5. Configure environment variables:
   - Add your Supabase credentials as encrypted environment variables
6. Set up code signing:
   - For iOS: Upload your distribution certificate and provisioning profile
   - For Android: Upload your keystore file
7. Run the build
8. Download the built apps or publish directly to stores

---

## App Store Submission Checklist

### Before Submitting to Apple

- [ ] Privacy policy URL is live and accessible
- [ ] App description written
- [ ] Screenshots for all required device sizes
- [ ] Demo account created with test data
- [ ] Location permission description is specific (not vague)
- [ ] Account deletion works
- [ ] App works offline (test in airplane mode)
- [ ] All placeholder text removed
- [ ] App icon set
- [ ] Bundle ID is unique (not `com.example.*`)

### Before Submitting to Google Play

- [ ] Privacy policy URL is live
- [ ] Data safety form completed
- [ ] Content rating questionnaire completed
- [ ] Target audience declaration completed
- [ ] Store listing assets uploaded
- [ ] Signed release bundle built
- [ ] Tested on multiple Android versions

---

## Common Rejection Reasons

### Apple Rejections

| Reason | Solution |
|--------|----------|
| Missing privacy policy | Add a privacy policy URL |
| Vague permission descriptions | Rewrite to be specific about why you need location/camera/etc. |
| Crashes during review | Test thoroughly on real devices |
| Incomplete features | Remove or finish all features before submitting |
| Demo account doesn't work | Verify credentials and pre-populate test data |
| Data collection not declared | Update App Privacy in App Store Connect |

### Google Play Rejections

| Reason | Solution |
|--------|----------|
| Privacy policy missing or inaccessible | Ensure URL works and policy covers your data use |
| Data safety incorrect | Re-complete the data safety form accurately |
| App targets children | Mark as 18+ in target audience |
| Missing permissions disclosure | Explain all permissions in the console |

---

## Alternative: Web App Only

If app store publishing is too complex, consider **web-only deployment**:

### Advantages
- No developer accounts needed
- No app review process
- Instant updates (no waiting for approval)
- Works on any device with a browser

### Disadvantages
- No home screen icon (users bookmark it)
- No push notifications
- Slightly worse offline support

### Deploy Flutter Web

```bash
cd flutter-app
flutter build web --release --base-href=/app/

# Upload build/web folder to any web host:
# - Vercel
# - Netlify
# - GitHub Pages
# - Your own server
```

Users access via browser URL and can "Add to Home Screen" on their phones.

---

## Cost Summary

| Item | Cost | Notes |
|------|------|-------|
| Apple Developer | $99/year | Required for iOS App Store |
| Google Play Developer | $25 one-time | Required for Google Play |
| Codemagic | Free | 500 build minutes/month |
| Web hosting (Vercel) | Free | For admin dashboard |
| Supabase | Free | Up to 500MB, 50K users |
| Mapbox | Free | 50K map loads/month |

**Minimum for mobile apps**: $124 first year, $99/year after
**Minimum for web only**: $0

---

## Getting Help

- **Flutter documentation**: [docs.flutter.dev](https://docs.flutter.dev)
- **Apple App Store help**: [developer.apple.com/support](https://developer.apple.com/support)
- **Google Play help**: [support.google.com/googleplay/android-developer](https://support.google.com/googleplay/android-developer)
- **Project issues**: [GitHub Issues](https://github.com/jotra7/grassroots-canvass/issues)
