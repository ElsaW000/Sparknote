import 'package:flutter/foundation.dart';

// 使用相对路径，避免跨域问题
const String _webDefaultBackend = '';
const String _androidEmulatorBackend = 'http://10.0.2.2:8000';

String get backendUrl => const String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: kIsWeb ? _webDefaultBackend : _androidEmulatorBackend,
    );
