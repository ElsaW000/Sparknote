# Mobile Client (Flutter)

This folder contains a lightweight skeleton for the Sparknote mobile (and desktop/web) client using Flutter. The goal is to provide a starting point with authentication, a notes list, and placeholders for chat/recording pages.

## Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed and on your `PATH`.
- Android emulator or physical device (iOS requires macOS for build).

## Initial setup

```bash
cd mobile
flutter pub get
```

## Environment variables

The app reads Supabase configuration from compile-time environment variables. Example when running locally:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xyz.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

For production builds you can set the `dart-define` in `flutter build` commands or via a `.env`/build script.

## Running the app

Start on Android emulator:

```bash
flutter run -d emulator-5554 \
  --dart-define=SUPABASE_URL=https://xyz.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

The login page accepts email/password; you can create users directly in Supabase Auth or extend the UI accordingly.

## Next steps

- Implement `NotesPage` to fetch `/notes` from backend and display them.
- Add voice/video recording and upload via Supabase Storage.
- Build chat UI and call `/conversations` endpoints.
- Add offline caching using `supabase-flutter` local storage or SQLite.
