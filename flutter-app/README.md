# Grassroots Canvass - Mobile App

Open-source voter canvassing app for grassroots political campaigns.

## Features

- **Voter List** - Search, filter, and sort voters by name, address, party, and contact status
- **Interactive Map** - View voters on a map with party-colored markers
- **Canvass Tracking** - Record contact results (Supportive, Undecided, Opposed, Not Home, etc.)
- **Cut Lists** - Filter by geographic territories assigned to your team
- **Bulk Actions** - Select multiple voters to copy phone numbers or export CSV
- **Offline Mode** - Works without internet, syncs when connected
- **Cloud Sync** - All data syncs to Supabase backend in real-time

## Platforms

- iOS
- Android
- Web

## Development

### Prerequisites

- Flutter SDK 3.10+
- Xcode 15+ (for iOS)
- Android Studio (for Android)
- CocoaPods (for iOS dependencies)

### Setup

```bash
# Get dependencies
flutter pub get

# iOS setup
cd ios && pod install && cd ..

# Run in development
flutter run
```

### Building

**iOS:**
```bash
flutter build ios --release
```

**Android:**
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

**Web:**
```bash
flutter build web --release
```

## Project Structure

```
lib/
  config/          # App configuration (Supabase)
  models/          # Data models (Voter, UserProfile, enums)
  providers/       # Riverpod state management
  screens/         # UI screens
    auth/          # Login, signup, pending approval
    voters/        # Voter list, detail, load screens
    map/           # Interactive map view
    settings/      # App settings
    admin/         # Admin user management
  services/        # API services (Supabase, CSV)
  widgets/         # Reusable UI components
```

## Tech Stack

- **Framework:** Flutter
- **State Management:** Riverpod
- **Backend:** Supabase (PostgreSQL + Auth)
- **Maps:** flutter_map with Mapbox tiles
- **Location:** geolocator
- **Offline Storage:** Drift (SQLite)

## License

AGPL-3.0 - See LICENSE file
