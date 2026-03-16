import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'ai_workspace.dart';
import '../utils/local_file_picker.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _HeatmapLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _HeatmapLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF60716F)),
        ),
      ],
    );
  }
}

class _NotesPageState extends State<NotesPage> {
  static const Color _brand = Color(0xFF2D6A4F);
  static const Color _brandDark = Color(0xFF1A3C34);
  static const Color _paper = Color(0xFFFCFDFC);
  static const Color _panel = Color(0xFFD8E2DC);
  static const Color _ink = Color(0xFF263238);
  static const Color _muted = Color(0xFF60716F);
  static const Color _line = Color(0xFFC6D6CD);
  static const Color _softText = Color(0xFFE7F1EC);

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _quickInputCtrl = TextEditingController();
  final TextEditingController _quickTagsCtrl = TextEditingController();

  List<dynamic> _notes = [];
  List<PickedLocalFile> _quickAttachments = [];
  List<dynamic> _tagSuggestions = [];
  List<dynamic> _heatmap = [];
  List<dynamic> _dailyReview = [];
  bool _loading = false;
  bool _creatingQuickNote = false;
  bool _uploadingQuickAttachment = false;
  String? _loadError;
  String? _quickAttachmentStatus;
  String? _selectedTag;
  String? _selectedDate;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _quickInputCtrl.dispose();
    _quickTagsCtrl.dispose();
    super.dispose();
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  String _decodeResponse(http.Response response) {
    return utf8.decode(response.bodyBytes);
  }

  String _text(dynamic value) {
    final raw = value?.toString() ?? '';
    if (raw.isEmpty) return raw;
    try {
      return utf8.decode(latin1.encode(raw));
    } catch (_) {
      return raw;
    }
  }

  Future<void> _refreshDashboard() async {
    await Future.wait([
      _fetchNotes(),
      _fetchTagSuggestions(),
      _fetchHeatmap(),
      _fetchDailyReview(),
    ]);
  }

  Future<void> _fetchNotes() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() => _loadError = '登录状态已失效，请重新登录。');
        return;
      }

      final queryParameters = <String, String>{};
      if (_selectedTag != null && _selectedTag!.isNotEmpty) {
        queryParameters['tag'] = _selectedTag!;
      }
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        queryParameters['q'] = _searchQuery!;
      }

      final uri = Uri.parse('$backendUrl/notes').replace(
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

      final r = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;
      if (r.statusCode == 200) {
        setState(() => _notes = json.decode(_decodeResponse(r)) as List<dynamic>);
      } else {
        setState(() => _loadError = '加载笔记失败：${r.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = '网络错误：$e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _fetchTagSuggestions() async {
    final token = await _token();
    if (token == null || token.isEmpty) return;

    try {
      final r = await http.get(
        Uri.parse('$backendUrl/tags/suggest'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        setState(() => _tagSuggestions = json.decode(_decodeResponse(r)) as List<dynamic>);
      }
    } catch (_) {}
  }

  Future<void> _fetchHeatmap() async {
    final token = await _token();
    if (token == null || token.isEmpty) return;

    try {
      final r = await http.get(
        Uri.parse('$backendUrl/stats/heatmap'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        setState(() => _heatmap = json.decode(_decodeResponse(r)) as List<dynamic>);
      }
    } catch (_) {}
  }

  Future<void> _fetchDailyReview() async {
    final token = await _token();
    if (token == null || token.isEmpty) return;

    try {
      final r = await http.get(
        Uri.parse('$backendUrl/review/daily'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        setState(() => _dailyReview = json.decode(_decodeResponse(r)) as List<dynamic>);
      }
    } catch (_) {}
  }

  Future<void> _openDailyReviewNote(Map<String, dynamic> item) async {
    final noteId = item['id'];
    if (noteId is! int) {
      await _openNoteEditor(note: item);
      return;
    }

    final token = await _token();
    if (!mounted || token == null || token.isEmpty) return;

    try {
      final resp = await http.get(
        Uri.parse('$backendUrl/notes/$noteId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final note = json.decode(_decodeResponse(resp)) as Map<String, dynamic>;
        await _openNoteEditor(note: note);
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('加载完整笔记失败，请稍后重试。')),
    );
  }

  void _applySearch() {
    final value = _searchCtrl.text.trim();
    setState(() => _searchQuery = value.isEmpty ? null : value);
    _fetchNotes();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _searchQuery = null);
    _fetchNotes();
  }

  Future<void> _createQuickNote() async {
    final messenger = ScaffoldMessenger.of(context);
    final parsed = _parseQuickInput(_quickInputCtrl.text);
    final content = parsed.content;
    if (content.isEmpty || _creatingQuickNote) {
      if (content.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text('先写一点内容再发送。')));
      }
      return;
    }

    final token = await _token();
    if (!mounted || token == null || token.isEmpty) return;

    setState(() => _creatingQuickNote = true);
    try {
      final resp = await http.post(
        Uri.parse('$backendUrl/notes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': parsed.title,
          'content': content,
          'tags': _quickTagsCtrl.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
        }),
      );

      if (!mounted) return;
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final created = json.decode(_decodeResponse(resp)) as Map<String, dynamic>;
        final noteId = created['id'] as int?;
        if (noteId != null && _quickAttachments.isNotEmpty) {
          await _uploadQuickAttachments(noteId, token);
        }
        _quickInputCtrl.clear();
        _quickTagsCtrl.clear();
        setState(() {
          _quickAttachments = [];
          _quickAttachmentStatus = null;
        });
        await _refreshDashboard();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('创建失败：${resp.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('创建失败：$e')));
    } finally {
      if (mounted) {
        setState(() => _creatingQuickNote = false);
      }
    }
  }

  Future<void> _transcribeAudioToQuickInput() async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await pickLocalFile(accept: 'audio/*');
    if (picked == null) return;
    try {
      final token = await _token();
      if (!mounted || token == null || token.isEmpty) return;
      final r = await http.post(
        Uri.parse('$backendUrl/audio/transcribe'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'mime_type': picked.mimeType,
          'content_base64': base64Encode(picked.bytes),
          'context': '请将语音转成适合灵感记录的简体中文文本，尽量保留语义。',
        }),
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        final data = json.decode(_decodeResponse(r)) as Map<String, dynamic>;
        final transcript = (data['transcript'] ?? '').toString().trim();
        if (transcript.isNotEmpty) {
          setState(() {
            _quickInputCtrl.text = transcript;
            _quickInputCtrl.selection = TextSelection.collapsed(
              offset: _quickInputCtrl.text.length,
            );
          });
          messenger.showSnackBar(const SnackBar(content: Text('语音已转写到快速输入框')));
        }
      } else {
        messenger.showSnackBar(SnackBar(content: Text('转写失败：${r.statusCode}')));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('转写失败：$e')));
    }
  }

  _QuickInputPayload _parseQuickInput(String rawInput) {
    final normalized = rawInput.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) {
      return const _QuickInputPayload(title: null, content: '');
    }

    final lines = normalized.split('\n');
    final firstLine = lines.first.trim();
    if (firstLine.startsWith('#')) {
      final title = firstLine.replaceFirst(RegExp(r'^#+'), '').trim();
      final body = lines.skip(1).join('\n').trim();
      if (title.isNotEmpty) {
        return _QuickInputPayload(
          title: title,
          content: body.isEmpty ? title : body,
        );
      }
    }
    return _QuickInputPayload(title: null, content: normalized);
  }

  String _displayTitle(Map<String, dynamic> note) {
    final title = _text(note['title'] ?? '').trim();
    if (title.isNotEmpty) return title;
    return '未命名灵感';
  }

  List<dynamic> _visibleNotes() {
    if (_selectedDate == null || _selectedDate!.isEmpty) {
      return _notes;
    }
    return _notes.where((item) {
      if (item is! Map<String, dynamic>) return false;
      return (item['created_at']?.toString() ?? '').startsWith(_selectedDate!);
    }).toList();
  }

  String _dailyReviewSummary() {
    if (_dailyReview.isEmpty) {
      return '今天还没有新的灵感沉淀，写下一条记录后这里会自动出现回顾。';
    }
    final titles = _dailyReview
        .whereType<Map<String, dynamic>>()
        .map(_displayTitle)
        .where((title) => title.isNotEmpty)
        .take(3)
        .toList();
    final count = _dailyReview.length;
    if (titles.isEmpty) {
      return '今天共记录了 $count 条内容，可以从下方卡片继续回看。';
    }
    return '今天共记录了 $count 条内容，重点包括 ${titles.join('、')}。';
  }

  Future<void> _pickQuickAttachment({required String accept}) async {
    if (_uploadingQuickAttachment) return;
    setState(() => _uploadingQuickAttachment = true);
    try {
      final picked = await pickLocalFile(accept: accept);
      if (picked == null || !mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      setState(() {
        _quickAttachments = [..._quickAttachments, picked];
        _quickAttachmentStatus = '已添加 ${picked.name}';
      });
      messenger.showSnackBar(SnackBar(content: Text('已添加 ${picked.name}')));
    } finally {
      if (mounted) {
        setState(() => _uploadingQuickAttachment = false);
      }
    }
  }

  void _removeQuickAttachment(PickedLocalFile file) {
    setState(() {
      _quickAttachments = _quickAttachments.where((item) => item != file).toList();
      if (_quickAttachments.isEmpty) {
        _quickAttachmentStatus = null;
      }
    });
  }

  Future<void> _uploadQuickAttachments(int noteId, String token) async {
    for (final file in _quickAttachments) {
      await http.post(
        Uri.parse('$backendUrl/notes/$noteId/attachments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'file_name': file.name,
          'mime_type': file.mimeType,
          'content_base64': base64Encode(file.bytes),
        }),
      );
    }
  }

  void _openWorkspaceForNote(Map<String, dynamic> note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AIWorkspacePage(
          noteId: note['id'] as int? ?? 0,
          noteTitle: _text(note['title'] ?? ''),
          noteContent: _text(note['content'] ?? ''),
        ),
      ),
    );
  }

  Future<void> _openWorkspaceLauncher() async {
    String query = '';
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final matches = _notes.whereType<Map<String, dynamic>>().where((note) {
              final title = _displayTitle(note).toLowerCase();
              final content = _text(note['content'] ?? '').toLowerCase();
              final keyword = query.trim().toLowerCase();
              if (keyword.isEmpty) return true;
              return title.contains(keyword) || content.contains(keyword);
            }).toList();
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '选择要进入工作台的笔记',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _ink),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '可以直接搜索标题或正文，再进入灵感延展、AI 对话和草稿整理。',
                        style: TextStyle(fontSize: 13, color: _muted, height: 1.6),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (value) => setModalState(() => query = value),
                        decoration: _fieldDecoration('搜索想进入工作台的笔记'),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: matches.isEmpty
                            ? const Center(
                                child: Text(
                                  '没有找到匹配的笔记。',
                                  style: TextStyle(color: _muted),
                                ),
                              )
                            : ListView.separated(
                                itemCount: matches.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (_, index) {
                                  final note = matches[index];
                                  return InkWell(
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _openWorkspaceForNote(note);
                                    },
                                    borderRadius: BorderRadius.circular(18),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: _line),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _displayTitle(note),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: _ink,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _text(note['content'] ?? ''),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              height: 1.6,
                                              color: _muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openNoteEditor({Map<String, dynamic>? note}) async {
    final existingAttachments = note == null
        ? <Map<String, dynamic>>[]
        : (note['attachments'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
    final titleCtrl = TextEditingController(
      text: (note?['title'] ?? '').toString(),
    );
    final contentCtrl = TextEditingController(
      text: (note?['content'] ?? '').toString(),
    );
    final tagsCtrl = TextEditingController(
      text: note == null
          ? ''
          : ((note['tags'] as List<dynamic>? ?? [])
                .map((e) => e.toString())
                .join(', ')),
    );

    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note == null ? '新建笔记' : '编辑笔记',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '长笔记适合整理标题、正文和标签；底部快速输入更适合即时捕捉灵感。',
                          style: TextStyle(fontSize: 13, color: _muted, height: 1.6),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: titleCtrl,
                          decoration: _fieldDecoration('标题（可选）'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: contentCtrl,
                          maxLines: 8,
                          decoration: _fieldDecoration('正文'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: tagsCtrl,
                          decoration: _fieldDecoration('标签，用逗号分隔'),
                        ),
                        if (existingAttachments.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          const Text(
                            '已保存附件',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: existingAttachments.map((attachment) {
                              final fileName = _text(attachment['file_name'] ?? '').trim();
                              final mimeType = _text(attachment['mime_type'] ?? '').trim();
                              return InputChip(
                                label: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 240),
                                  child: Text(
                                    fileName.isEmpty ? '未命名附件' : fileName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                avatar: Icon(
                                  mimeType.startsWith('image/')
                                      ? Icons.image_outlined
                                      : Icons.attach_file_outlined,
                                  size: 18,
                                ),
                                onPressed: () {},
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _brand,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('保存'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (submit != true) return;

    final token = await _token();
    if (!mounted || token == null || token.isEmpty) return;

    final content = contentCtrl.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正文不能为空')),
      );
      return;
    }

    try {
      final body = json.encode({
        'title': titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
        'content': content,
        'tags': tagsCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      });

      final uri = note == null
          ? Uri.parse('$backendUrl/notes')
          : Uri.parse('$backendUrl/notes/${note['id']}');

      final resp = note == null
          ? await http.post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: body,
            )
          : await http.patch(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: body,
            );

      if (!mounted) return;
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        await _refreshDashboard();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：${resp.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    }
  }

  Future<void> _deleteNote(int id) async {
    final token = await _token();
    if (!mounted || token == null || token.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除笔记'),
        content: const Text('这条笔记会从当前账号中移除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      final resp = await http.delete(
        Uri.parse('$backendUrl/notes/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (resp.statusCode == 200) {
        await _refreshDashboard();
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _openApiIntegration() {
    Navigator.of(context).pushNamed('/notion-integration');
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: _paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }

  Color _tagColor(String tag) {
    final normalized = _text(tag).toLowerCase();
    if (normalized.contains('小说') || normalized.contains('novel')) {
      return const Color(0xFF2196F3);
    }
    if (normalized.contains('产品') || normalized.contains('product')) {
      return const Color(0xFF4CAF50);
    }
    if (normalized.contains('内容') || normalized.contains('content')) {
      return const Color(0xFFFF9800);
    }
    if (normalized.contains('技术') || normalized.contains('tech')) {
      return const Color(0xFF9C27B0);
    }
    return const Color(0xFF90A4AE);
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString() ?? '';
    if (raw.isEmpty) return '刚刚记录';
    return raw.length >= 16 ? raw.substring(0, 16).replaceFirst('T', ' ') : raw;
  }

  int _todayCount() {
    final today = DateTime.now();
    final prefix =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return _heatmap
        .where((e) => (e['date']?.toString() ?? '').startsWith(prefix))
        .fold<int>(0, (sum, e) => sum + ((e['count'] as int?) ?? 0));
  }

  int _activeDays() {
    return _heatmap.where((e) => ((e['count'] as int?) ?? 0) > 0).length;
  }

  Widget _buildTagChips() {
    final chips = <Widget>[
      ChoiceChip(
        label: const Text('全部'),
        selected: _selectedTag == null,
        onSelected: (_) {
          setState(() => _selectedTag = null);
          _fetchNotes();
        },
      ),
    ];

    for (final item in _tagSuggestions.take(10)) {
      final tag = item['tag']?.toString();
      if (tag == null || tag.isEmpty) continue;
      chips.add(
        ChoiceChip(
          label: Text('#$tag'),
          selected: _selectedTag == tag,
          onSelected: (_) {
            setState(() => _selectedTag = _selectedTag == tag ? null : tag);
            _fetchNotes();
          },
        ),
      );
    }

    return Wrap(spacing: 10, runSpacing: 10, children: chips);
  }

  Widget _buildHeatmapSection() {
    final counts = <String, int>{};
    for (final entry in _heatmap) {
      final date = entry['date']?.toString();
      if (date == null) continue;
      counts[date] = (entry['count'] as int?) ?? 0;
    }

    final maxCount = counts.values.isEmpty
        ? 0
        : counts.values.reduce((a, b) => a > b ? a : b);

    Color colorForCount(int count) {
      if (count <= 0) return Colors.grey.shade300;
      if (maxCount <= 1) return const Color(0xFF2D6A4F);
      final ratio = count / maxCount;
      if (ratio >= 0.85) return const Color(0xFF1B4332);
      if (ratio >= 0.60) return const Color(0xFF2D6A4F);
      if (ratio >= 0.35) return const Color(0xFF40916C);
      return const Color(0xFF95D5B2);
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(35, (index) {
        final day = DateTime.now().subtract(Duration(days: 34 - index));
        final key =
            '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final count = counts[key] ?? 0;
        final selected = _selectedDate == key;
        return Tooltip(
          message: '$key · $count 条',
          child: InkWell(
            onTap: count == 0
                ? null
                : () {
                    setState(() {
                      _selectedDate = selected ? null : key;
                    });
                  },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: colorForCount(count),
                borderRadius: BorderRadius.circular(4),
                border: selected ? Border.all(color: _brandDark, width: 1.5) : null,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDailyReviewSection() {
    if (_dailyReview.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今天还没有可回顾的笔记。',
            style: TextStyle(fontSize: 13, color: _muted),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _dailyReview.take(5).map((item) {
        if (item is Map<String, dynamic>) {
          item['title'] = _text(item['title'] ?? '未命名');
          item['content'] = _text(item['content'] ?? '');
        }
        return InkWell(
          onTap: item is Map<String, dynamic> ? () => _openDailyReviewNote(item) : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _brand.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.article_outlined, color: _brandDark, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item is Map<String, dynamic> ? _displayTitle(item) : '未命名灵感',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _text(item['content'] ?? '').trim().isEmpty
                            ? '点击查看今天这条记录的完整内容。'
                            : _text(item['content'] ?? ''),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _brandDark),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(
    Map<String, dynamic> note, {
    required bool compact,
    required int displayIndex,
  }) {
    note['title'] = _text(note['title'] ?? '');
    note['content'] = _text(note['content'] ?? '');
    final tags = (note['tags'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110E1A13),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayTitle(note),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: compact ? null : 'Georgia',
                        fontSize: compact ? 18 : 22,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(note['created_at']),
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '第 $displayIndex 条',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _text(note['content'] ?? ''),
            maxLines: compact ? 4 : 6,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.75,
              color: _ink,
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.take(compact ? 3 : 5).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _tagColor(tag).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _tagColor(tag),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openNoteEditor(note: note),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('\u7f16\u8f91'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _openWorkspaceForNote(note);
                },
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('灵感工作台'),
              ),
              IconButton.filledTonal(
                onPressed: () => _deleteNote(note['id'] as int),
                icon: const Icon(Icons.delete_outline),
                tooltip: '删除',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeftRail() {
    return Container(
      width: 290,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandDark, _brand],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.eco_outlined, color: _brandDark),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sparknote',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '灵感流与工作台',
                          style: TextStyle(color: _softText, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '今天的创作脉搏',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${_todayCount()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '条灵感被记录',
                      style: TextStyle(color: _softText),
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 18),
                    Text(
                      '${_activeDays()} 天',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '近 35 天有记录',
                      style: TextStyle(color: _softText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '标签索引',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: _tagSuggestions.isEmpty
                          ? const Text(
                              '还没有标签建议。',
                              style: TextStyle(color: _softText),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _tagSuggestions.take(12).map((item) {
                                final tag = item['tag']?.toString() ?? '';
                                if (tag.isEmpty) return const SizedBox.shrink();
                                final selected = _selectedTag == tag;
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedTag = selected ? null : tag;
                                    });
                                    _fetchNotes();
                                  },
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '#$tag',
                                      style: TextStyle(
                                        color: selected ? _brandDark : Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
                onPressed: _openApiIntegration,
                icon: const Icon(Icons.api_outlined),
                label: const Text('API连接'),
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('退出登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterPanel({required bool isDesktop}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 42, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(_loadError!, style: const TextStyle(color: _ink)),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                ),
                onPressed: _fetchNotes,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(isDesktop ? 28 : 18, 24, isDesktop ? 28 : 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDesktop ? '灵感流' : '今天的灵感流',
                            style: TextStyle(
                              fontSize: isDesktop ? 34 : 28,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '像聊天一样捕捉碎片，再把值得发展的部分送进灵感工作台。',
                            style: TextStyle(fontSize: 14, color: _muted, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _brand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () => _openNoteEditor(),
                      icon: const Icon(Icons.add),
                      label: const Text('新建长笔记'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: isDesktop ? 220 : double.infinity,
                      child: _buildMetricCard(
                        label: '总笔记数',
                        value: '${_notes.length}',
                        icon: Icons.notes_outlined,
                      ),
                    ),
                    SizedBox(
                      width: isDesktop ? 220 : double.infinity,
                      child: _buildMetricCard(
                        label: '今日记录',
                        value: '${_todayCount()}',
                        icon: Icons.today_outlined,
                      ),
                    ),
                    SizedBox(
                      width: isDesktop ? 220 : double.infinity,
                      child: _buildMetricCard(
                        label: '活跃天数',
                        value: '${_activeDays()}',
                        icon: Icons.local_fire_department_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _line),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _applySearch(),
                              decoration: _fieldDecoration('搜索标题或正文'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _brand,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(72, 54),
                            ),
                            onPressed: _applySearch,
                            child: const Text('搜索'),
                          ),
                          if (_searchQuery != null) ...[
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: _clearSearch,
                              child: const Text('清除'),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildTagChips(),
                      ),
                      if (_searchQuery != null || _selectedTag != null || _selectedDate != null) ...[
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '当前条件：${_searchQuery == null ? '全部内容' : '搜索 "$_searchQuery"'}${_selectedTag == null ? '' : ' · 标签 #$_selectedTag'}${_selectedDate == null ? '' : ' · 日期 $_selectedDate'}',
                            style: const TextStyle(fontSize: 13, color: _muted),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_visibleNotes().isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '还没有笔记，先从底部快速输入写下第一条灵感。',
                  style: TextStyle(fontSize: 15, color: _muted),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(isDesktop ? 28 : 18, 0, isDesktop ? 28 : 18, 140),
            sliver: SliverList.builder(
              itemCount: _visibleNotes().length,
              itemBuilder: (context, index) {
                final note = _visibleNotes()[index] as Map<String, dynamic>;
                return _buildNoteCard(
                  note,
                  compact: !isDesktop,
                  displayIndex: index + 1,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRightPanel() {
    return Container(
      width: 360,
      color: _panel,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '记录热力图',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '近 35 天的记录强度，越深表示当天沉淀越多。',
                      style: TextStyle(fontSize: 12, color: _muted, height: 1.6),
                    ),
                    if (_selectedDate != null) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => setState(() => _selectedDate = null),
                        child: Text(
                          '当前筛选：$_selectedDate · 点击清除',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _brand,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _buildHeatmapSection(),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        _HeatmapLegendDot(color: Color(0xFFD9D9D9), label: '0'),
                        SizedBox(width: 8),
                        _HeatmapLegendDot(color: Color(0xFF95D5B2), label: '低'),
                        SizedBox(width: 8),
                        _HeatmapLegendDot(color: Color(0xFF40916C), label: '中'),
                        SizedBox(width: 8),
                        _HeatmapLegendDot(color: Color(0xFF2D6A4F), label: '高'),
                        SizedBox(width: 8),
                        _HeatmapLegendDot(color: Color(0xFF1B4332), label: '峰值'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: _brandDark, size: 18),
                        SizedBox(width: 8),
                        Text(
                          '今日回顾',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _brand.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _dailyReviewSummary(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: _ink,
                          height: 1.6,
                        ),
                      ),
                    ),
                    _buildDailyReviewSection(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _openWorkspaceLauncher,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _brandDark,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '灵感工作台',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '点击后可先搜索并选择一条笔记，再进入工作台做灵感提取、AI 对话和草稿整理。',
                        style: TextStyle(
                          color: _softText,
                          fontSize: 13,
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickComposer({required bool isDesktop}) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: EdgeInsets.fromLTRB(isDesktop ? 28 : 14, 0, isDesktop ? 28 : 14, 14),
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 920 : double.infinity),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A0E1A13),
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_quickAttachmentStatus != null || _quickAttachments.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_quickAttachments.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            '已选附件',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                        ),
                      if (_quickAttachmentStatus != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _quickAttachmentStatus!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _brand,
                            ),
                          ),
                        ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickAttachments.map((file) {
                          return InputChip(
                            label: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Text(
                                file.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            avatar: Icon(
                              (file.mimeType ?? '').startsWith('image/')
                                  ? Icons.image_outlined
                                  : Icons.attach_file_outlined,
                              size: 18,
                            ),
                            onDeleted: () => _removeQuickAttachment(file),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: _quickInputCtrl,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '像发消息一样写下此刻的灵感... 也可以用 #标题 换行后写正文',
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quickTagsCtrl,
                      decoration: const InputDecoration(
                        hintText: '标签，例如 小说, 人物, 产品',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: _uploadingQuickAttachment
                        ? null
                        : () => _pickQuickAttachment(accept: 'image/*'),
                    tooltip: '添加图片',
                    style: IconButton.styleFrom(
                      backgroundColor: _quickAttachments.any(
                        (file) => (file.mimeType ?? '').startsWith('image/'),
                      )
                          ? _brand.withValues(alpha: 0.16)
                          : null,
                    ),
                    icon: Icon(
                      _uploadingQuickAttachment ? Icons.hourglass_top : Icons.image_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _uploadingQuickAttachment
                        ? null
                        : () => _pickQuickAttachment(accept: '.pdf,.doc,.docx,.txt'),
                    tooltip: '添加文件',
                    style: IconButton.styleFrom(
                      backgroundColor: _quickAttachments.any(
                        (file) => !((file.mimeType ?? '').startsWith('image/')),
                      )
                          ? _brand.withValues(alpha: 0.16)
                          : null,
                    ),
                    icon: Icon(
                      _uploadingQuickAttachment ? Icons.hourglass_top : Icons.attach_file_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _transcribeAudioToQuickInput,
                    tooltip: '导入音频转写',
                    icon: const Icon(Icons.mic_none_outlined),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _brand,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(108, 48),
                    ),
                    onPressed: _creatingQuickNote ? null : _createQuickNote,
                    icon: _creatingQuickNote
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: const Text('发送'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: _paper,
      body: Stack(
        children: [
          Row(
            children: [
              _buildLeftRail(),
              Expanded(child: _buildCenterPanel(isDesktop: true)),
              _buildRightPanel(),
            ],
          ),
          _buildQuickComposer(isDesktop: true),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        surfaceTintColor: Colors.transparent,
        title: const Text('Sparknote'),
        actions: [
          IconButton(
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 150),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_brandDark, _brand],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '灵感流',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '快速记录，稍后再进入灵感工作台整理和延展。',
                      style: TextStyle(color: _softText, height: 1.6),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            label: '今日记录',
                            value: '${_todayCount()}',
                            icon: Icons.flash_on_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            label: '总笔记数',
                            value: '${_notes.length}',
                            icon: Icons.library_books_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _line),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onSubmitted: (_) => _applySearch(),
                      decoration: _fieldDecoration('搜索标题或正文'),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildTagChips(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 180,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '热力图',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildHeatmapSection(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_loadError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text(_loadError!)),
                )
              else if (_visibleNotes().isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    '还没有笔记，先从底部快速输入写下第一条灵感。',
                    style: TextStyle(fontSize: 15, color: _muted),
                  ),
                )
              else
                ..._visibleNotes().asMap().entries.map(
                  (entry) => _buildNoteCard(
                    entry.value as Map<String, dynamic>,
                    compact: true,
                    displayIndex: entry.key + 1,
                  ),
                ),
            ],
          ),
          _buildQuickComposer(isDesktop: false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        onPressed: () => _openNoteEditor(),
        icon: const Icon(Icons.add),
        label: const Text('长笔记'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1180;
    return isDesktop ? _buildDesktopLayout() : _buildMobileLayout();
  }
}

class _QuickInputPayload {
  final String? title;
  final String content;

  const _QuickInputPayload({
    required this.title,
    required this.content,
  });
}



