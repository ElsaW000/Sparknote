import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const backendUrl = String.fromEnvironment('BACKEND_URL', defaultValue: 'http://10.0.2.2:8000');

class NotesPage extends StatefulWidget {
  const NotesPage({Key? key}) : super(key: key);

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final GlobalKey<_NotesListState> _listKey = GlobalKey<_NotesListState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Calendar',
            onPressed: () => _listKey.currentState?.openCalendarView(),
          ),
        ],
      ),
      body: NotesList(key: _listKey),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _listKey.currentState?.openCreateDialog(),
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

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> openCreateDialog() async {
    await _openNoteEditor();
  }

  DateTime _dayOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTime? _noteDay(Map<String, dynamic> note) {
    final raw = note['created_at']?.toString();
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return _dayOnly(parsed.toLocal());
  }

  Map<DateTime, List<Map<String, dynamic>>> _notesByDay() {
    final grouped = <DateTime, List<Map<String, dynamic>>>{};
    for (final item in _notes) {
      final note = item as Map<String, dynamic>;
      final day = _noteDay(note);
      if (day == null) continue;
      grouped.putIfAbsent(day, () => <Map<String, dynamic>>[]).add(note);
    }
    return grouped;
  }

  Future<void> openCalendarView() async {
    final grouped = _notesByDay();
    if (grouped.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No dated notes yet.')),
      );
      return;
    }

    final days = grouped.keys.toList()..sort();
    final first = days.first;
    final last = days.last;
    final today = _dayOnly(DateTime.now());
    final initial = grouped.containsKey(today) ? today : last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      selectableDayPredicate: (d) => grouped.containsKey(_dayOnly(d)),
      helpText: 'Select a day with note',
    );
    if (picked == null || !mounted) return;

    final day = _dayOnly(picked);
    final notes = grouped[day] ?? [];
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...notes.map(
                (n) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text((n['title'] ?? 'Untitled').toString()),
                  subtitle: Text(
                    (n['content'] ?? '').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openNoteEditor({Map<String, dynamic>? note}) async {
    final titleCtrl = TextEditingController(text: (note?['title'] ?? '').toString());
    final contentCtrl = TextEditingController(text: (note?['content'] ?? '').toString());
    final tagsCtrl = TextEditingController(
      text: note == null
          ? ''
          : ((note['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).join(', ')),
    );
    final isEdit = note != null;

    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Note' : 'Create Note'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: contentCtrl,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Content'),
              ),
              TextField(
                controller: tagsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'work, idea, todo',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (submit != true) return;

    final token = await _token();
    if (token == null) return;

    final body = json.encode({
      'title': titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
      'content': contentCtrl.text.trim(),
      'tags': _parseTags(tagsCtrl.text),
    });

    try {
      final uri = isEdit
          ? Uri.parse('$backendUrl/notes/${note['id']}')
          : Uri.parse('$backendUrl/notes');
      final resp = isEdit
          ? await http.patch(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: body,
            )
          : await http.post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: body,
            );
      if (resp.statusCode == 200) {
        await _fetchNotes();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: ${resp.statusCode}')),
        );
      }
    } catch (_) {}
  }

  Future<void> _deleteNote(Map<String, dynamic> note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('This will delete "${note['title'] ?? 'Untitled'}".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;

    final token = await _token();
    if (token == null) return;
    try {
      final resp = await http.delete(
        Uri.parse('$backendUrl/notes/${note['id']}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        await _fetchNotes();
      }
    } catch (_) {}
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
        await Navigator.pushNamed(context, '/chat', arguments: cid);
        await _fetchNotes();
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_notes.isEmpty) return const Center(child: Text('No notes yet. Tap + to create one.'));
    return RefreshIndicator(
      onRefresh: _fetchNotes,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _notes.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (ctx, i) {
          final n = _notes[i] as Map<String, dynamic>;
          final tags = (n['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
          return ListTile(
            title: Text(n['title'] ?? 'Untitled'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (n['content'] ?? '').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _noteDay(n)?.toString().split(' ').first ?? 'unknown date',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tags.map((t) => Chip(label: Text(t), visualDensity: VisualDensity.compact)).toList(),
                    ),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _openNoteEditor(note: n);
                if (v == 'delete') _deleteNote(n);
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
            onTap: () => _openChatForNote(n),
          );
        },
      ),
    );
  }
}
