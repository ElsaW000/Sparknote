import 'package:flutter/foundation.dart';

const String _webDefaultBackend = 'http://127.0.0.1:8000';
const String _androidEmulatorBackend = 'http://10.0.2.2:8000';

String get backendUrl => const String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: kIsWeb ? _webDefaultBackend : _androidEmulatorBackend,
    );
