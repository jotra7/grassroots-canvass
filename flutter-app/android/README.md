# Android Build & Play Store Guide

Complete guide to building and publishing Grassroots Canvass for Android.

---

## Prerequisites

- Android Studio installed
- Flutter SDK 3.10+
- Google Play Developer account ($25 one-time fee)
- Keystore for signing (created below)

---

## Quick Build

```bash
cd flutter-app
flutter pub get
flutter build apk --release        # APK for testing
flutter build appbundle --release  # AAB for Play Store
```

**Output locations:**
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

---

## Step-by-Step Setup

### 1. Configure App Identity

Edit `android/app/build.gradle.kts`:

```kotlin
android {
    namespace = "com.yourcampaign.canvass"  // Your unique ID

    defaultConfig {
        applicationId = "com.yourcampaign.canvass"  // Must match namespace
        minSdk = 21
        targetSdk = 34
        versionCode = 1        // Increment for each release
        versionName = "1.0.0"  // User-visible version
    }
}
```

### 2. Create a Signing Keystore

**Important:** Keep your keystore safe. If lost, you cannot update your app.

```bash
keytool -genkey -v -keystore ~/grassroots-canvass.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias grassroots-canvass
```

You'll be prompted for:
- Keystore password (save this!)
- Your name, organization, location
- Key password (can be same as keystore password)

### 3. Configure Signing

Create `android/key.properties` (do NOT commit this file):

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=grassroots-canvass
storeFile=/Users/yourname/grassroots-canvass.jks
```

Add to `android/app/build.gradle.kts`:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
```

### 4. Update App Icon

Replace the launcher icons in:
```
android/app/src/main/res/
├── mipmap-hdpi/ic_launcher.png      (72x72)
├── mipmap-mdpi/ic_launcher.png      (48x48)
├── mipmap-xhdpi/ic_launcher.png     (96x96)
├── mipmap-xxhdpi/ic_launcher.png    (144x144)
├── mipmap-xxxhdpi/ic_launcher.png   (192x192)
```

Or use the flutter_launcher_icons package:

```yaml
# In pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  image_path: "assets/icon.png"
```

Then run: `flutter pub run flutter_launcher_icons`

### 5. Build for Release

```bash
flutter build appbundle --release
```

---

## Google Play Store Submission

### 1. Create Developer Account

1. Go to [play.google.com/console](https://play.google.com/console)
2. Pay $25 registration fee
3. Complete identity verification (government ID required)
4. Wait 24-48 hours for approval

### 2. Create App in Play Console

1. Click **Create app**
2. Fill in:
   - App name: "Grassroots Canvass" (or your campaign name)
   - Default language: English
   - App or game: App
   - Free or paid: Free
3. Accept policies

### 3. Complete Store Listing

**App Details:**
- Short description (80 chars): "Voter canvassing app for grassroots campaigns"
- Full description (4000 chars): Describe features and benefits

**Graphics:**
- App icon: 512x512 PNG
- Feature graphic: 1024x500 PNG
- Screenshots: At least 2 phone screenshots (16:9 or 9:16)

**Categorization:**
- Category: Tools or Productivity
- Tags: "canvassing", "campaign", "voter outreach"

### 4. Complete App Content

**Privacy Policy:**
- Required URL to your privacy policy
- Must cover data collection and usage

**App Access:**
- Select "All functionality is available without special access"
- Or provide demo credentials if login required

**Ads:**
- Select "No, my app does not contain ads"

**Content Rating:**
Complete the questionnaire:
- Violence: None
- Sexual content: None
- Language: None
- Controlled substances: None

Result: **Rated for Everyone**

**Target Audience:**
- Age group: 18 and over
- Not designed for children

**Data Safety:**
Complete the form:

| Question | Answer |
|----------|--------|
| Does your app collect or share data? | Yes |
| Data types collected | Name, email, phone, location |
| Data encrypted in transit? | Yes |
| Can users request deletion? | Yes |
| Data shared with third parties? | No |

### 5. Upload App Bundle

1. Go to **Release** → **Production**
2. Click **Create new release**
3. Upload your `.aab` file
4. Add release notes
5. Click **Review release**
6. Click **Start rollout to Production**

### 6. Review Process

- Initial review: 2-7 days for new apps
- Updates: Usually 1-3 days

---

## Common Issues

### Build Fails: "Namespace not specified"

Add to `android/app/build.gradle.kts`:
```kotlin
android {
    namespace = "com.grassroots.canvass"
}
```

### Build Fails: "SDK not found"

Set `ANDROID_HOME` environment variable:
```bash
export ANDROID_HOME=~/Library/Android/sdk
```

### App Crashes on Launch

1. Check `adb logcat` for errors
2. Verify Supabase config is correct
3. Ensure internet permissions in AndroidManifest.xml

### Play Store Rejection: "Privacy Policy"

- Ensure privacy policy URL is accessible
- Must be hosted on a public website
- Must cover all data your app collects

### Play Store Rejection: "Data Safety"

- Re-check data safety form
- Ensure all collected data types are declared
- Be specific about location data usage

---

## Updating the App

1. Increment `versionCode` in build.gradle.kts
2. Update `versionName` if user-visible changes
3. Build new app bundle
4. Upload to Play Console
5. Add release notes
6. Submit for review

---

## Testing Before Release

### Internal Testing

1. Go to **Testing** → **Internal testing**
2. Create a release
3. Add testers by email
4. Testers install via Play Store link

### Open Testing (Beta)

1. Go to **Testing** → **Open testing**
2. Anyone can join and test
3. Good for broader feedback

---

## Files to Keep Secret

Never commit these:
- `key.properties` - Keystore passwords
- `*.jks` or `*.keystore` - Signing keys
- `google-services.json` - Firebase config (if using)

Add to `.gitignore`:
```
key.properties
*.jks
*.keystore
google-services.json
```

---

## Useful Commands

```bash
# Clean build
flutter clean && flutter pub get

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build app bundle (for Play Store)
flutter build appbundle --release

# Install on connected device
flutter install

# View logs
adb logcat | grep flutter
```
