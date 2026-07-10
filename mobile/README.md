# ResQLink Mobile App

The cross-platform mobile application for victims and volunteers in the ResQLink ecosystem.

## Features
- **One-Tap SOS:** Instantly broadcast your location and emergency status to nearby volunteers.
- **Automatic Crash Detection:** Background service utilizing device sensors to automatically detect accidents and trigger SOS protocols.
- **Continuous GPS Tracking:** Streams live location with high accuracy to the Supabase backend.
- **Volunteer Dashboard:** Real-time feed of nearby emergencies with one-tap dispatch acceptance.
- **Turn-by-Turn Navigation:** Deep linking into Google Maps to route volunteers directly to victims.

## Tech Stack
- **Framework:** [Flutter](https://flutter.dev/)
- **Language:** Dart
- **Backend Services:** Supabase Flutter SDK
- **Location & Sensors:** `geolocator`, `sensors_plus`, `flutter_background_service`

## Getting Started

1. **Get dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run the app:**
   Connect a physical device or start an emulator, then run:
   ```bash
   flutter run
   ```

## Background Services Note
This app uses `flutter_background_service` to poll for incidents and detect sensor spikes even when the app is terminated. Ensure you have the proper background execution permissions enabled on your Android/iOS device during testing.
