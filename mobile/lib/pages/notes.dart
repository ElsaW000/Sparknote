import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const backendUrl = String.fromEnvironment('BACKEND_URL', defaultValue: 'http://10.0.2.2:8000');

class NotesPage extends StatelessWidget {
  const NotesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: const NotesList(),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: () async {
          // trigger refresh by popping then pushing - simple approach
          Navigator.of(context).pushReplacementNamed('/notes');
        },
      ),
    );
  }
}


class NotesList extends StatefulWidget {
  const NotesList({Key? key}) : super(key: key);

  @override
  State<NotesList> createState() => _NotesListState();
}

class _NotesListState extends State<NotesList> {
  List<dynamic> _notes = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final r = await http.get(
        Uri.parse('$backendUrl/notes'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (r.statusCode == 200) {
        final list = json.decode(r.body) as List<dynamic>;
        setState(() => _notes = list);
      } else {
        // ignore for now
      }
    } catch (e) {
      // ignore errors in prototype
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openChatForNote(Map<String, dynamic> note) async {
    // create conversation with note title
    try {
      final title = note['title'] ?? 'Conversation';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final r = await http.post(
        Uri.parse('$backendUrl/conversations'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'title': title}),
      );
      if (r.statusCode == 200) {
        final conv = json.decode(r.body);
        final cid = conv['id'];
        Navigator.pushNamed(context, '/chat', arguments: cid);
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_notes.isEmpty) return Center(child: Text('No notes. Pull to refresh.'));
    return RefreshIndicator(
      onRefresh: _fetchNotes,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _notes.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (ctx, i) {
          final n = _notes[i] as Map<String, dynamic>;
          return ListTile(
            title: Text(n['title'] ?? 'Untitled'),
            subtitle: Text((n['content'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
            onTap: () => _openChatForNote(n),
          );
        },
      ),
    );
  }
}
