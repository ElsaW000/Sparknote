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

### Backend URL

For development the Flutter client will talk to a backend API. The default
is `http://127.0.0.1:8000` on the web and `http://10.0.2.2:8000` on
an Android emulator. You can override it with `BACKEND_URL`:

```bash
flutter run -d chrome \
  --dart-define=BACKEND_URL=http://localhost:8000
```

If you start seeing "XMLHttpRequest error" messages in the UI (often shown
as `请求异常`), it means the client couldn't reach the server or the
browser blocked the request due to CORS. Make sure the backend is running,
that the URL is reachable from your device/emulator, and that CORS is enabled
on the server (the prototype already allows all origins).

These errors are normal during development; the app now shows a clearer
warning instructing you to check the backend URL when they occur.

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
