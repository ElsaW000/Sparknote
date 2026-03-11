import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'pages/chat.dart';
import 'pages/login.dart';
import 'pages/notes.dart';
import 'pages/register.dart';
import 'pages/settings.dart';

void main() {
  runApp(const SparknoteApp());
}

class SparknoteApp extends StatelessWidget {
  const SparknoteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState()..initialize(),
      child: MaterialApp(
        title: 'Sparknote',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF388E3C), // Forest green
            brightness: Brightness.light,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const LoginPage(),
        routes: {
          '/notes': (ctx) => const NotesPage(),
          '/chat': (ctx) => const ChatPage(),
          '/register': (ctx) => const RegisterPage(),
          '/settings': (ctx) => const SettingsPage(),
        },
      ),
    );
  }
}
