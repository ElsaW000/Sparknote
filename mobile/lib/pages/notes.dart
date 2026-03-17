import 'dart:convert';
import 'dart:ui';

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

enum _WorkspaceMode {
  universal('通用灵感', Icons.auto_awesome_outlined, '适合自由整理、延展和总结'),
  product('产品灵感', Icons.lightbulb_outline, '适合问题拆解、方案构思和 PRD 草稿'),
  writing('写作灵感', Icons.edit_note_outlined, '适合人物、情节、章节和文风推进'),
  video('视频灵感', Icons.ondemand_video_outlined, '适合选题、脚本、分镜和节奏整理');

  const _WorkspaceMode(this.label, this.icon, this.description);

  final String label;
  final IconData icon;
  final String description;
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

class _RailPulseMetric extends StatelessWidget {
  final String value;
  final String label;

  const _RailPulseMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFE7F1EC), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CollapsedRailButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CollapsedRailButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
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
  static const double _h1Size = 24;
  static const double _sectionTitleSize = 16;
  static const double _bodySize = 14;
  static const double _bodyHeight = 1.6;

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
  bool _rightRailCollapsed = false;
  bool _leftRailCollapsed = false;
  String? _loadError;
  String? _quickAttachmentStatus;
  String? _selectedTag;
  String? _selectedDate;
  String? _searchQuery;

  static const double _expandedSideRailWidth = 280;
  static const double _collapsedLeftRailWidth = 92;
  static const double _collapsedRightRailWidth = 92;

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

  bool _looksLikeWorkspaceDraft(Map<String, dynamic> item) {
    final status = (item['workspace_status'] ?? '').toString();
    final title = _text(item['title'] ?? '');
    return status == 'open' || title.contains('草稿');
  }

  Future<void> _resumeWorkspaceFromNoteId(
    int noteId, {
    String fallbackWorkflowLabel = '通用灵感',
  }) async {
    final token = await _token();
    if (!mounted || token == null || token.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final resp = await http.get(
        Uri.parse('$backendUrl/workspace/notes/$noteId/resume'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final item = json.decode(_decodeResponse(resp)) as Map<String, dynamic>;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AIWorkspacePage(
              noteId: item['note_id'] as int? ?? noteId,
              noteTitle: _text(item['note_title']),
              noteContent: _text(item['note_content']),
              workflowLabel: _text(item['workflow_label']).isEmpty
                  ? fallbackWorkflowLabel
                  : _text(item['workflow_label']),
              sourceNoteCount: item['source_count'] as int? ?? 1,
              conversationId: item['conversation_id'] as int?,
            ),
          ),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('恢复工作台失败：${resp.statusCode}')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('恢复工作台失败：$e')));
    }
  }

  Future<void> _openDailyReviewNote(Map<String, dynamic> item) async {
    final noteId = item['id'];
    if (noteId is! int) {
      await _openNoteEditor(note: item);
      return;
    }

    if (_looksLikeWorkspaceDraft(item)) {
      await _resumeWorkspaceFromNoteId(
        noteId,
        fallbackWorkflowLabel: _text(item['workspace_mode']).isEmpty
            ? '通用灵感'
            : _text(item['workspace_mode']),
      );
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
        final workspaceCid = note['workspace_conversation_id'] as int?;
        final workspaceStatus = (note['workspace_status'] ?? '').toString();
        if (workspaceCid != null && workspaceStatus == 'open') {
          _openWorkspaceForNote(
            note,
            workflowLabel: _text(note['workspace_mode']).isEmpty
                ? '通用灵感'
                : _text(note['workspace_mode']),
            sourceNoteCount: note['workspace_source_count'] as int? ?? 1,
            conversationId: workspaceCid,
          );
        } else {
          await _openNoteEditor(note: note);
        }
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

  double get _leftRailWidth =>
      _leftRailCollapsed ? _collapsedLeftRailWidth : _expandedSideRailWidth;

  double get _rightRailWidth =>
      _rightRailCollapsed ? _collapsedRightRailWidth : _expandedSideRailWidth;

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

  List<String> _dailyReviewHighlights() {
    final highlights = <String>[];

    void addHighlight(String value, {bool prefixTag = false}) {
      final normalized = value.trim();
      if (normalized.isEmpty) return;
      final displayValue = prefixTag ? '#$normalized' : normalized;
      if (!highlights.contains(displayValue)) {
        highlights.add(displayValue);
      }
    }

    for (final item in _dailyReview.whereType<Map<String, dynamic>>()) {
      final title = _text(item['title'] ?? '').trim();
      if (title.isNotEmpty) {
        addHighlight(title);
      }

      final tags = item['tags'];
      if (tags is List) {
        for (final tag in tags) {
          addHighlight(_text(tag), prefixTag: true);
        }
      }
    }

    if (highlights.isEmpty) {
      for (final item in _dailyReview.whereType<Map<String, dynamic>>()) {
        final content = _text(item['content'] ?? '').trim();
        if (content.isEmpty) continue;
        final firstLine = content.split('\n').first.trim();
        if (firstLine.isNotEmpty) {
          addHighlight(firstLine);
        }
      }
    }

    return highlights.take(4).toList();
  }

  String _dailyReviewSummary() {
    if (_dailyReview.isEmpty) {
      return '今天还没有新的灵感沉淀，写下一条记录后这里会自动出现回顾。';
    }
    final highlights = _dailyReviewHighlights();
    if (highlights.isNotEmpty) {
      return '今天聚焦：${highlights.join(' · ')}。';
    }
    return '今天沉淀了 ${_dailyReview.length} 条记录，已经形成可继续延展的一组灵感线索。';
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

  void _openWorkspaceForNote(
    Map<String, dynamic> note, {
    String workflowLabel = '通用灵感',
    int sourceNoteCount = 1,
    int? conversationId,
  }) {
    final derivedConversationId =
        conversationId ?? ((note['workspace_status'] ?? '').toString() == 'open'
            ? note['workspace_conversation_id'] as int?
            : null);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AIWorkspacePage(
          noteId: note['id'] as int? ?? 0,
          noteTitle: _text(note['title'] ?? ''),
          noteContent: _text(note['content'] ?? ''),
          workflowLabel: _text(note['workspace_mode']).isNotEmpty
              ? _text(note['workspace_mode'])
              : workflowLabel,
          sourceNoteCount: note['workspace_source_count'] as int? ?? sourceNoteCount,
          conversationId: derivedConversationId,
        ),
      ),
    );
  }

  Future<void> _openWorkspaceLauncher() async {
    String query = '';
    var selectedMode = _WorkspaceMode.universal;
    final selectedIds = <int>{};

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allNotes = _notes.whereType<Map<String, dynamic>>().toList();
            final matches = allNotes.where((note) {
              final title = _displayTitle(note).toLowerCase();
              final content = _text(note['content'] ?? '').toLowerCase();
              final keyword = query.trim().toLowerCase();
              if (keyword.isEmpty) return true;
              return title.contains(keyword) || content.contains(keyword);
            }).toList();
            final selectedNotes = allNotes
                .where((note) => selectedIds.contains(note['id'] as int?))
                .toList();

            return Dialog(
              backgroundColor: Colors.white.withValues(alpha: 0.96),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040, maxHeight: 720),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '灵感工作台',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _ink),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '先选择工作流模式，再勾选一条或多条灵感素材，最后进入对应工作台。',
                        style: TextStyle(fontSize: 13, color: _muted, height: 1.6),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 286,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '第一步 · 选择模式',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _muted,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._WorkspaceMode.values.map((mode) {
                                    final active = mode == selectedMode;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: InkWell(
                                        onTap: () => setModalState(() => selectedMode = mode),
                                        borderRadius: BorderRadius.circular(22),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 180),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: active
                                                ? _brand.withValues(alpha: 0.12)
                                                : const Color(0xFFF8F9F8),
                                            borderRadius: BorderRadius.circular(22),
                                            border: Border.all(
                                              color: active ? _brand : _line,
                                              width: active ? 1.4 : 1,
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  color: active ? _brandDark : Colors.white,
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                child: Icon(
                                                  mode.icon,
                                                  color: active ? Colors.white : _brandDark,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      mode.label,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w700,
                                                        color: active ? _brandDark : _ink,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      mode.description,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: _muted,
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '第二步 · 选择素材',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _muted,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    onChanged: (value) => setModalState(() => query = value),
                                    decoration: _fieldDecoration('搜索想进入工作台的笔记'),
                                  ),
                                  const SizedBox(height: 14),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: matches.isEmpty
                                              ? const Center(
                                                  child: Text(
                                                    '没有找到匹配的笔记。',
                                                    style: TextStyle(color: _muted),
                                                  ),
                                                )
                                              : ListView.separated(
                                                  itemCount: matches.length,
                                                  separatorBuilder: (_, __) =>
                                                      const SizedBox(height: 10),
                                                  itemBuilder: (_, index) {
                                                    final note = matches[index];
                                                    final noteId = note['id'] as int? ?? 0;
                                                    final active = selectedIds.contains(noteId);
                                                    return InkWell(
                                                      onTap: () {
                                                        setModalState(() {
                                                          if (active) {
                                                            selectedIds.remove(noteId);
                                                          } else {
                                                            selectedIds.add(noteId);
                                                          }
                                                        });
                                                      },
                                                      borderRadius: BorderRadius.circular(18),
                                                      child: AnimatedContainer(
                                                        duration: const Duration(milliseconds: 180),
                                                        padding: const EdgeInsets.all(16),
                                                        decoration: BoxDecoration(
                                                          color: active
                                                              ? _brand.withValues(alpha: 0.10)
                                                              : Colors.white,
                                                          borderRadius:
                                                              BorderRadius.circular(18),
                                                          border: Border.all(
                                                            color: active ? _brand : _line,
                                                          ),
                                                        ),
                                                        child: Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment.start,
                                                          children: [
                                                            Checkbox(
                                                              value: active,
                                                              activeColor: _brand,
                                                              onChanged: (_) {
                                                                setModalState(() {
                                                                  if (active) {
                                                                    selectedIds.remove(noteId);
                                                                  } else {
                                                                    selectedIds.add(noteId);
                                                                  }
                                                                });
                                                              },
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment.start,
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
                                                                    _formatDate(note['created_at']),
                                                                    style: const TextStyle(
                                                                      fontSize: 12,
                                                                      color: Color(0xFF999999),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8F9F8),
                                              borderRadius: BorderRadius.circular(22),
                                              border: Border.all(color: _line),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  '已选预览',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: _ink,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  selectedNotes.isEmpty
                                                      ? '还没有选择笔记。可单选，也可多选后整合进入工作台。'
                                                      : '已选 ${selectedNotes.length} 条素材，将按 ${selectedMode.label} 模式进入工作台。',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: _muted,
                                                    height: 1.6,
                                                  ),
                                                ),
                                                const SizedBox(height: 14),
                                                Expanded(
                                                  child: selectedNotes.isEmpty
                                                      ? const SizedBox.shrink()
                                                      : ListView.separated(
                                                          itemCount: selectedNotes.length,
                                                          separatorBuilder: (_, __) =>
                                                              const SizedBox(height: 8),
                                                          itemBuilder: (_, index) {
                                                            final note = selectedNotes[index];
                                                            return Container(
                                                              padding: const EdgeInsets.all(12),
                                                              decoration: BoxDecoration(
                                                                color: Colors.white,
                                                                borderRadius:
                                                                    BorderRadius.circular(16),
                                                                border: Border.all(color: _line),
                                                              ),
                                                              child: Text(
                                                                _displayTitle(note),
                                                                maxLines: 2,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: const TextStyle(
                                                                  fontSize: 13,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: _ink,
                                                                  height: 1.5,
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
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('取消'),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _brand,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                            ),
                            onPressed: selectedIds.isEmpty
                                ? null
                                : () async {
                                    final selected = allNotes
                                        .where((note) => selectedIds.contains(note['id'] as int?))
                                        .toList();
                                    Navigator.pop(ctx);
                                    if (selected.isEmpty) return;
                                    if (selected.length == 1) {
                                      _openWorkspaceForNote(
                                        selected.first,
                                        workflowLabel: selectedMode.label,
                                        sourceNoteCount: 1,
                                      );
                                      return;
                                    }

                                    final token = await _token();
                                    if (!mounted || token == null || token.isEmpty) return;
                                    final mergedTitle = '${selectedMode.label}整合草稿';
                                    final mergedTags = selected
                                        .expand((note) => (note['tags'] as List<dynamic>? ?? []))
                                        .map((tag) => _text(tag).trim())
                                        .where((tag) => tag.isNotEmpty)
                                        .toSet()
                                        .toList();
                                    final mergedContent = selected.map((note) {
                                      final title = _displayTitle(note);
                                      final content = _text(note['content'] ?? '').trim();
                                      return '【$title】\n$content';
                                    }).join('\n\n');
                                    try {
                                      final resp = await http.post(
                                        Uri.parse('$backendUrl/notes'),
                                        headers: {
                                          'Content-Type': 'application/json',
                                          'Authorization': 'Bearer $token',
                                        },
                                        body: json.encode({
                                          'title': mergedTitle,
                                          'content': mergedContent,
                                          'tags': mergedTags,
                                        }),
                                      );
                                      if (!mounted) return;
                                      if (resp.statusCode == 200 || resp.statusCode == 201) {
                                        final mergedNote = json.decode(_decodeResponse(resp))
                                            as Map<String, dynamic>;
                                        await _refreshDashboard();
                                        if (!mounted) return;
                                        _openWorkspaceForNote(
                                          mergedNote,
                                          workflowLabel: selectedMode.label,
                                          sourceNoteCount: selected.length,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('创建整合草稿失败：${resp.statusCode}'),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('创建整合草稿失败：$e')),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('进入工作台'),
                          ),
                        ],
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
    var pendingAttachments = <PickedLocalFile>[];
    var pickingEditorAttachment = false;
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
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickEditorAttachment(String accept) async {
            if (pickingEditorAttachment) return;
            setModalState(() => pickingEditorAttachment = true);
            try {
              final picked = await pickLocalFile(accept: accept);
              if (picked == null || !context.mounted) return;
              setModalState(() {
                pendingAttachments = [...pendingAttachments, picked];
              });
            } finally {
              if (context.mounted) {
                setModalState(() => pickingEditorAttachment = false);
              }
            }
          }

          return Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760, maxHeight: 780),
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
                              '长笔记适合整理标题、正文、标签和附件；底部快速输入更适合即时捕捉灵感。',
                              style: TextStyle(fontSize: 13, color: _muted, height: 1.6),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: titleCtrl,
                              decoration: _editorFieldDecoration(
                                label: '标题',
                                hint: '标题（可选）',
                                fillColor: const Color(0xFFF4FAF6),
                                borderColor: const Color(0xFF2D6A4F),
                                icon: Icons.title_rounded,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: contentCtrl,
                              maxLines: 8,
                              decoration: _editorFieldDecoration(
                                label: '正文',
                                hint: '正文（必填）',
                                fillColor: const Color(0xFFFFFBF2),
                                borderColor: const Color(0xFFB7791F),
                                icon: Icons.notes_rounded,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: tagsCtrl,
                              decoration: _editorFieldDecoration(
                                label: '标签',
                                hint: '多个标签请用逗号分隔，如 产品, 测试, 文本',
                                fillColor: const Color(0xFFF4F7FF),
                                borderColor: const Color(0xFF4C6FFF),
                                icon: Icons.sell_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(148, 44),
                                      alignment: Alignment.centerLeft,
                                    ),
                                    onPressed: pickingEditorAttachment
                                        ? null
                                        : () => pickEditorAttachment('image/*'),
                                    icon: Icon(
                                      pickingEditorAttachment
                                          ? Icons.hourglass_top
                                          : Icons.image_outlined,
                                    ),
                                    label: const Text('上传图片'),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(148, 44),
                                      alignment: Alignment.centerLeft,
                                    ),
                                    onPressed: pickingEditorAttachment
                                        ? null
                                        : () => pickEditorAttachment(
                                            '.pdf,.doc,.docx,.txt,.md,.ppt,.pptx,.xls,.xlsx',
                                          ),
                                    icon: Icon(
                                      pickingEditorAttachment
                                          ? Icons.hourglass_top
                                          : Icons.attach_file_outlined,
                                    ),
                                    label: const Text('上传文件'),
                                  ),
                                ],
                              ),
                            ),
                            if (pendingAttachments.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              const Text(
                                '待上传附件',
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
                                children: pendingAttachments.map((file) {
                                  final mimeType = file.mimeType ?? '';
                                  return InputChip(
                                    label: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 240),
                                      child: Text(
                                        file.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    avatar: Icon(
                                      mimeType.startsWith('image/')
                                          ? Icons.image_outlined
                                          : Icons.attach_file_outlined,
                                      size: 18,
                                    ),
                                    onDeleted: () {
                                      setModalState(() {
                                        pendingAttachments = pendingAttachments
                                            .where((item) => item != file)
                                            .toList();
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
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
          );
        },
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
        'tags': _parseTagInput(tagsCtrl.text),
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
        final savedNote = json.decode(_decodeResponse(resp)) as Map<String, dynamic>;
        final savedNoteId = savedNote['id'] as int?;
        if (savedNoteId != null && pendingAttachments.isNotEmpty) {
          for (final file in pendingAttachments) {
            await http.post(
              Uri.parse('$backendUrl/notes/$savedNoteId/attachments'),
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

  void _openSettings() {
    Navigator.of(context).pushNamed('/settings');
  }

  void _openApiDocs() {
    Navigator.of(context).pushNamed('/notion-integration');
  }

  List<String> _parseTagInput(String raw) {
    return raw
        .split(RegExp(r'[,，]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
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

  InputDecoration _editorFieldDecoration({
    required String label,
    required String hint,
    required Color fillColor,
    required Color borderColor,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: borderColor),
      labelStyle: TextStyle(
        color: borderColor,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: TextStyle(
        color: borderColor,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor.withValues(alpha: 0.38)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor.withValues(alpha: 0.38)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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

  Widget _buildSearchUtilityCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _applySearch(),
                  style: const TextStyle(
                    fontSize: _bodySize,
                    color: _ink,
                    height: _bodyHeight,
                  ),
                  decoration: InputDecoration(
                    hintText: '搜索...',
                    hintStyle: const TextStyle(
                      fontSize: _bodySize,
                      color: Color(0xFF666666),
                      height: _bodyHeight,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8F9F8),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _brand, width: 1.2),
                    ),
                    prefixIcon: const Icon(Icons.search, size: 18, color: _muted),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _applySearch,
                tooltip: '搜索',
                style: IconButton.styleFrom(
                  backgroundColor: _brand.withValues(alpha: 0.10),
                  foregroundColor: _brandDark,
                  minimumSize: const Size(36, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.search, size: 18),
              ),
              if (_searchQuery != null && _searchQuery!.isNotEmpty) ...[
                const SizedBox(width: 6),
                IconButton(
                  onPressed: _clearSearch,
                  tooltip: '清除',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF8F9F8),
                    foregroundColor: _muted,
                    minimumSize: const Size(36, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ],
          ),
          if (_searchQuery != null && _searchQuery!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '正在搜索 “$_searchQuery”',
              style: const TextStyle(
                fontSize: _bodySize,
                color: Color(0xFF666666),
                height: _bodyHeight,
              ),
            ),
          ],
        ],
      ),
    );
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
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
                          if (item is Map<String, dynamic> &&
                              (item['workspace_status'] ?? '').toString() == 'open')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7F5EC),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                '进行中',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _brand,
                                ),
                              ),
                            ),
                        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _brandDark, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: _bodySize, color: Color(0xFF666666), height: _bodyHeight),
              ),
            ],
          ),
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
    final visibleTags = tags.take(2).toList();

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 22 : 28),
      constraints: compact
          ? null
          : const BoxConstraints(
              minHeight: 168,
              maxHeight: 168,
            ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _displayTitle(note),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: compact ? null : 'Georgia',
                        fontSize: _sectionTitleSize,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _brand.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '第 $displayIndex 条',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _brandDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(note['created_at']),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                  height: _bodyHeight,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _text(note['content'] ?? ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: _bodySize,
                  height: _bodyHeight,
                  color: Color(0xFF444444),
                ),
              ),
            ],
          ),
          if (compact)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (visibleTags.isNotEmpty)
                  ...visibleTags.map((tag) {
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
                  }),
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
            )
          else
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: visibleTags.map((tag) {
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
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _openNoteEditor(note: note),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('\u7f16\u8f91'),
                ),
                const SizedBox(width: 8),
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
                const SizedBox(width: 8),
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
    final collapsed = _leftRailCollapsed;
    return Container(
      width: _leftRailWidth,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandDark, _brand],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(collapsed ? 14 : 20, 18, collapsed ? 14 : 20, 20),
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
                  if (!collapsed) ...[
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
                            style: TextStyle(color: _softText, fontSize: _bodySize, height: _bodyHeight),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    const Spacer(),
                  IconButton(
                    tooltip: collapsed ? '展开侧栏' : '收起侧栏',
                    onPressed: () => setState(() => _leftRailCollapsed = !_leftRailCollapsed),
                    icon: Icon(
                      collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              if (!collapsed) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '创作脉搏',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _RailPulseMetric(
                              value: '${_todayCount()}',
                              label: '今日记录',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _RailPulseMetric(
                              value: '${_activeDays()}',
                              label: '活跃天数',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  '标签索引',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: ListView(
                  children: [
                    if (!collapsed) ...[
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
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.folder_open_outlined, color: Colors.white70, size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '笔记本功能后续会支持按项目、主题、阶段收纳笔记。',
                                style: TextStyle(color: _softText, height: _bodyHeight, fontSize: _bodySize),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Center(
                        child: Wrap(
                          direction: Axis.vertical,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _CollapsedRailButton(
                              icon: Icons.label_outline,
                              tooltip: '标签筛选',
                              onTap: () {},
                            ),
                            _CollapsedRailButton(
                              icon: Icons.folder_open_outlined,
                              tooltip: '笔记本',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (!collapsed) ...[
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('设置'),
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _openApiDocs,
                  icon: const Icon(Icons.api_outlined),
                  label: const Text('API文档'),
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('退出登录'),
                ),
              ] else ...[
                Center(
                  child: Wrap(
                    direction: Axis.vertical,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _CollapsedRailButton(
                        icon: Icons.settings_outlined,
                        tooltip: '设置',
                        onTap: _openSettings,
                      ),
                      _CollapsedRailButton(
                        icon: Icons.api_outlined,
                        tooltip: 'API文档',
                        onTap: _openApiDocs,
                      ),
                      _CollapsedRailButton(
                        icon: Icons.logout,
                        tooltip: '退出登录',
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
              ],
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Text(
                            isDesktop ? '灵感流' : '今天的灵感流',
                            style: TextStyle(
                              fontSize: _h1Size,
                              fontWeight: FontWeight.w600,
                              color: _ink,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '底部输入适合碎片捕捉，右上按钮适合整理成长笔记。',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF999999),
                                height: _bodyHeight,
                                shadows: [
                                  Shadow(
                                    color: Color(0x14000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _brand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: isDesktop ? 204 : double.infinity,
                      child: _buildMetricCard(
                        label: '总笔记数',
                        value: '${_notes.length}',
                        icon: Icons.notes_outlined,
                      ),
                    ),
                    SizedBox(
                      width: isDesktop ? 204 : double.infinity,
                      child: _buildMetricCard(
                        label: '今日记录',
                        value: '${_todayCount()}',
                        icon: Icons.today_outlined,
                      ),
                    ),
                    SizedBox(
                      width: isDesktop ? 204 : double.infinity,
                      child: _buildMetricCard(
                        label: '活跃天数',
                        value: '${_activeDays()}',
                        icon: Icons.local_fire_department_outlined,
                      ),
                    ),
                  ],
                ),
                if (_searchQuery != null || _selectedTag != null || _selectedDate != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '当前条件：${_searchQuery == null ? '全部内容' : '搜索 "$_searchQuery"'}${_selectedTag == null ? '' : ' · 标签 #$_selectedTag'}${_selectedDate == null ? '' : ' · 日期 $_selectedDate'}',
                    style: const TextStyle(fontSize: _bodySize, color: Color(0xFF666666), height: _bodyHeight),
                  ),
                ],
                const SizedBox(height: 10),
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
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 28 : 18,
              8,
              isDesktop ? 28 : 18,
              isDesktop ? 312 : 196,
            ),
            sliver: SliverList.builder(
              itemCount: _visibleNotes().length,
              itemBuilder: (context, index) {
                final note = _visibleNotes()[index] as Map<String, dynamic>;
                return _buildNoteCard(
                  note,
                  compact: !isDesktop,
                  displayIndex: _visibleNotes().length - index,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRightPanel({required double width}) {
    final compactRail = width < 340;
    final outerPadding = compactRail ? 14.0 : 18.0;
    final cardPadding = compactRail ? 16.0 : 18.0;
    final collapsed = _rightRailCollapsed;

    return Container(
      width: width,
      color: _panel,
      child: SafeArea(
        child: Stack(
          children: [
            if (!collapsed)
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(outerPadding, 20, outerPadding, 116),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: '收起右栏',
                        onPressed: () => setState(() => _rightRailCollapsed = true),
                        icon: const Icon(Icons.chevron_right_rounded, color: _brandDark),
                      ),
                    ),
                    _buildSearchUtilityCard(),
                    const SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.fromLTRB(cardPadding, cardPadding, cardPadding, cardPadding + 2),
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
                              fontSize: _sectionTitleSize,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '近 35 天的记录强度，越深表示当天沉淀越多。',
                            style: TextStyle(
                              fontSize: _bodySize,
                              color: Color(0xFF666666),
                              height: _bodyHeight,
                            ),
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
                          const SizedBox(height: 20),
                          _buildHeatmapSection(),
                          const SizedBox(height: 12),
                          const Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _HeatmapLegendDot(color: Color(0xFFD9D9D9), label: '0'),
                              _HeatmapLegendDot(color: Color(0xFF95D5B2), label: '低'),
                              _HeatmapLegendDot(color: Color(0xFF40916C), label: '中'),
                              _HeatmapLegendDot(color: Color(0xFF2D6A4F), label: '高'),
                              _HeatmapLegendDot(color: Color(0xFF1B4332), label: '峰值'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(cardPadding),
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
                                  fontSize: _sectionTitleSize,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: _brand.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _dailyReviewSummary(),
                              style: const TextStyle(
                                fontSize: _bodySize,
                                color: _ink,
                                height: _bodyHeight,
                              ),
                            ),
                          ),
                          _buildDailyReviewSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 20, 14, 20),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: '展开右栏',
                        onPressed: () => setState(() => _rightRailCollapsed = false),
                        icon: const Icon(Icons.chevron_left_rounded, color: _brandDark),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CollapsedRailButton(
                      icon: Icons.search_rounded,
                      tooltip: '展开搜索与回顾面板',
                      onTap: () => setState(() => _rightRailCollapsed = false),
                    ),
                    const SizedBox(height: 12),
                    _CollapsedRailButton(
                      icon: Icons.calendar_view_month_rounded,
                      tooltip: '热力图',
                      onTap: () => setState(() => _rightRailCollapsed = false),
                    ),
                    const SizedBox(height: 12),
                    _CollapsedRailButton(
                      icon: Icons.auto_awesome,
                      tooltip: '今日回顾',
                      onTap: () => setState(() => _rightRailCollapsed = false),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            Positioned(
              right: outerPadding,
              bottom: 18,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openWorkspaceLauncher,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: collapsed ? 14 : 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _brandDark,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x221A3C34),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                        if (!collapsed) ...[
                          const SizedBox(width: 10),
                          const Text(
                            '灵感工作台',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickComposer({required bool isDesktop}) {
    final composerCard = ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 948 : double.infinity),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xD6D8E5DC)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120E1A13),
                blurRadius: 18,
                offset: Offset(0, 8),
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

    if (isDesktop) {
      return Positioned(
        left: _leftRailWidth + 28,
        right: _rightRailWidth + 28,
        bottom: 18,
        child: SafeArea(
          minimum: const EdgeInsets.only(bottom: 18),
          child: composerCard,
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: composerCard,
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
              Container(
                width: 14,
                color: Colors.transparent,
                alignment: Alignment.center,
                child: Container(
                  width: 4,
                  height: 86,
                  decoration: BoxDecoration(
                    color: _line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              _buildRightPanel(width: _rightRailWidth),
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
                    displayIndex: _visibleNotes().length - entry.key,
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



