import 'package:flutter/material.dart';

import 'pages/login.dart';
import 'pages/notes.dart';

class SparknoteApp extends StatelessWidget {
  const SparknoteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sparknote',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const LoginPage(),
      routes: {
        '/notes': (ctx) => const NotesPage(),
        '/chat': (ctx) => const ChatPage(),
      },
    );
  }
}
