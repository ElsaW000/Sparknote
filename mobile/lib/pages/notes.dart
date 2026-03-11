import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'ai_workspace.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<dynamic> _notes = [];
  bool _loading = false;
  String? _loadError;
  String? _selectedNav = 'today';

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null || token.isEmpty) {
        setState(() => _loadError = '登录状态已失效');
        return;
      }
      final r = await http.get(
        Uri.parse('$backendUrl/notes'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) {
        final list = json.decode(r.body) as List<dynamic>;
        setState(() => _notes = list);
      } else {
        setState(() => _loadError = '加载失败');
      }
    } catch (e) {
      setState(() => _loadError = '网络错误：$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _openNoteEditor({Map<String, dynamic>? note}) async {
    final titleCtrl = TextEditingController(text: (note?['title'] ?? '').toString());
    final contentCtrl = TextEditingController(text: (note?['content'] ?? '').toString());
    final tagsCtrl = TextEditingController(
      text: note == null
          ? ''
          : ((note['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).join(', ')),
    );

    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(note == null ? '新建笔记' : '编辑笔记'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '标题'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 5,
                decoration: const InputDecoration(labelText: '内容'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagsCtrl,
                decoration: const InputDecoration(labelText: '标签'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (submit != true) return;

    final token = await _token();
    if (token == null) return;

    final content = contentCtrl.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('内容不能为空')));
      return;
    }

    try {
      final body = json.encode({
        'title': titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
        'content': content,
        'tags': tagsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      });

      final uri = note == null
          ? Uri.parse('$backendUrl/notes')
          : Uri.parse('$backendUrl/notes/${note['id']}');

      final resp = note == null
          ? await http.post(uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: body)
          : await http.patch(uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: body);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        await _fetchNotes();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('错误：$e')));
    }
  }

  Future<void> _deleteNote(int id) async {
    final token = await _token();
    if (token == null) return;
    try {
      final resp = await http.delete(
        Uri.parse('$backendUrl/notes/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        await _fetchNotes();
      }
    } catch (_) {}
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final tags = (note['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((note['title'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  note['title'] ?? '未命名',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Expanded(
              child: Text(
                (note['content'] ?? '').toString(),
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            if (tags.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: tags.take(3).map((t) {
                  Color tagColor;
                  if (t.toLowerCase().contains('novel')) {
                    tagColor = Colors.blue;
                  } else if (t.toLowerCase().contains('product')) {
                    tagColor = Colors.green;
                  } else {
                    tagColor = Colors.orange;
                  }
                  return Chip(
                    label: Text(t, style: const TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: tagColor,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _openNoteEditor(note: note),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('编辑'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => AIWorkspacePage(
                          noteId: note['id'] as int? ?? 0,
                          noteTitle: (note['title'] ?? '').toString(),
                          noteContent: (note['content'] ?? '').toString(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('AI 续写'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF388E3C),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    const sidebarColor = Color(0xFF2E7D32); // Darker forest green
    return Container(
      width: 280,
      color: sidebarColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.edit, size: 24, color: Color(0xFF2E7D32)),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sparknote',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.home_outlined,
                  label: 'Today\'s Stream',
                  id: 'today',
                  color: sidebarColor,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.calendar_today_outlined,
                  label: 'Calendar & Heatmap',
                  id: 'calendar',
                  color: sidebarColor,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.label_outline,
                  label: 'Collections',
                  id: 'collections',
                  color: sidebarColor,
                ),
                const Divider(color: Colors.white24, height: 32),
                _buildNavItem(
                  context,
                  icon: Icons.star_outline,
                  label: 'Favorites',
                  id: 'favorites',
                  color: sidebarColor,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  id: 'settings',
                  color: sidebarColor,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Log Out', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('access_token');
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String id,
    required Color color,
  }) {
    final isSelected = _selectedNav == id;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
      title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
      selected: isSelected,
      selectedTileColor: Colors.white12,
      onTap: () {
        if (id == 'settings') {
          Navigator.pushNamed(context, '/settings');
        } else {
          setState(() => _selectedNav = id);
        }
      },
    );
  }

  Widget _buildMainContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_loadError!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchNotes, child: const Text('重试')),
          ],
        ),
      );
    }
    if (_notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No notes yet', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _notes.length,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildNoteCard(_notes[i] as Map<String, dynamic>),
      ),
    );
  }

  Widget _buildAIPanel() {
    return Container(
      width: 320,
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Activity',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Simple heatmap visualization
                  Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: List.generate(35, (i) {
                      final colors = [Colors.grey[300], Colors.blue[300], Colors.green[400]];
                      return Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colors[i % 3],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome, size: 14, color: Colors.green[700]),
                                const SizedBox(width: 4),
                                Text(
                                  'AI Summary (P0)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Focus: Self-mastery\nTheme: Freedom & Insight\nSource: Unknown.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                      ),
                      child: const Text('AI Continue (P1)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    if (!isDesktop) {
      // Mobile/Tablet layout
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sparknote'),
          elevation: 0,
        ),
        body: _buildMainContent(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openNoteEditor(),
          child: const Icon(Icons.add),
        ),
      );
    }

    // Desktop 3-column layout
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(context),
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  AppBar(
                    title: const Text('Today\'s Notes (12)'),
                    elevation: 0,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _openNoteEditor(),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  Expanded(child: _buildMainContent()),
                ],
              ),
            ),
          ),
          _buildAIPanel(),
        ],
      ),
    );
  }
}
