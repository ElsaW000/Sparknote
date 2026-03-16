import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pages/chat.dart';
import 'pages/login.dart';
import 'pages/notes.dart';
import 'pages/notion_integration.dart';
import 'pages/register.dart';
import 'pages/settings.dart';

void main() {
  runApp(const SparknoteApp());
}

class SparknoteApp extends StatelessWidget {
  const SparknoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    const brandDark = Color(0xFF1A3C34);
    const brand = Color(0xFF2D6A4F);
    const mint = Color(0xFFD8E2DC);

    return MaterialApp(
      title: 'Sparknote',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brand,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFCFDFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFCFDFC),
          surfaceTintColor: Colors.transparent,
          foregroundColor: brandDark,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: brand,
            foregroundColor: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brand,
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: brand,
            side: const BorderSide(color: brand),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: mint),
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
        '/notion-integration': (ctx) => const NotionIntegrationPage(),
        '/settings': (ctx) => const SettingsPage(),
        '/register': (ctx) => const RegisterPage(),
      },
    );
  }
}
