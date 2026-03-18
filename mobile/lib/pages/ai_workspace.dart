import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../utils/local_file_picker.dart';

enum _WorkspaceLayoutMode { editorFocus, chatFocus }

class AIWorkspacePage extends StatefulWidget {
  final int noteId;
  final String noteTitle;
  final String noteContent;
  final String workflowLabel;
  final int sourceNoteCount;
  final int? conversationId;

  const AIWorkspacePage({
    super.key,
    required this.noteId,
    required this.noteTitle,
    required this.noteContent,
    this.workflowLabel = '通用灵感',
    this.sourceNoteCount = 1,
    this.conversationId,
  });

  @override
  State<AIWorkspacePage> createState() => _AIWorkspacePageState();
}

class _AIWorkspacePageState extends State<AIWorkspacePage> {
  static const Color _brand = Color(0xFF2D6A4F);
  static const Color _brandDark = Color(0xFF1A3C34);
  static const Color _paper = Color(0xFFFCFDFC);
  static const Color _ink = Color(0xFF263238);
  static const Color _panel = Color(0xFFD8E2DC);
  static const Color _line = Color(0xFFC6D6CD);

  final List<String> _suggestions = const [
    '点击灵感提取，帮我拆出 3 个可扩展方向',
    '提炼这一页的核心冲突和下一步转折',
    '从当前笔记里抽取人物、主题和意象线索',
    '从产品经理视角提炼问题、机会和下一步方案',
  ];

  late final TextEditingController _contentCtrl;
  late final TextEditingController _productPortraitCtrl;
  late final TextEditingController _chatInputCtrl;
  final ScrollController _messageScrollCtrl = ScrollController();
  final ScrollController _editorScrollCtrl = ScrollController();
  final FocusNode _editorFocusNode = FocusNode();
  final FocusNode _productPortraitFocusNode = FocusNode();

  Timer? _poller;
  List<dynamic> _messages = [];
  List<Map<String, dynamic>> _attachments = [];
  int? _conversationId;
  double _assistantPanelWidth = 390;
  bool _initializing = true;
  bool _sending = false;
  bool _saving = false;
  bool _closing = false;
  bool _uploadingAttachment = false;
  bool _waitingForAi = false;
  bool _autoStickToBottom = true;
  String? _workspaceError;
  String? _statusNote;
  _WorkspaceLayoutMode _layoutMode = _WorkspaceLayoutMode.editorFocus;

  List<dynamic> _workspaceHistory = [];

  @override
  void initState() {
    super.initState();
    _contentCtrl = TextEditingController(text: _text(widget.noteContent));
    _productPortraitCtrl = TextEditingController(text: _deriveProductPortrait(widget.noteContent));
    _chatInputCtrl = TextEditingController();
    _messageScrollCtrl.addListener(_handleMessageScroll);
    _bootstrapWorkspace();
  }

  @override
  void dispose() {
    _poller?.cancel();
    _messageScrollCtrl.removeListener(_handleMessageScroll);
    _contentCtrl.dispose();
    _productPortraitCtrl.dispose();
    _chatInputCtrl.dispose();
    _messageScrollCtrl.dispose();
    _editorScrollCtrl.dispose();
    _editorFocusNode.dispose();
    _productPortraitFocusNode.dispose();
    super.dispose();
  }

  void _handleMessageScroll() {
    if (!_messageScrollCtrl.hasClients) return;
    final remaining =
        _messageScrollCtrl.position.maxScrollExtent - _messageScrollCtrl.position.pixels;
    final shouldStick = remaining < 48;
    if (shouldStick != _autoStickToBottom) {
      setState(() => _autoStickToBottom = shouldStick);
    }
  }

  void _jumpToBottom({bool animated = true}) {
    if (!_messageScrollCtrl.hasClients) return;
    final target = _messageScrollCtrl.position.maxScrollExtent + 48;
    if (animated) {
      _messageScrollCtrl.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      _messageScrollCtrl.jumpTo(target);
    }
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

  String get _resolvedWorkflowLabel {
    final raw = _text(widget.workflowLabel).trim();
    if (raw.isEmpty || RegExp(r'^\?+$').hasMatch(raw)) {
      final title = _text(widget.noteTitle);
      if (title.contains('产品')) return '产品灵感';
      if (title.contains('视频') || title.contains('脚本')) return '视频灵感';
      if (title.contains('写作') || title.contains('文章') || title.contains('小说')) {
        return '写作灵感';
      }
      return '通用灵感';
    }
    return raw;
  }

  bool get _isProductMode => _resolvedWorkflowLabel.contains('产品');
  bool get _isWritingMode => _resolvedWorkflowLabel.contains('写作');
  bool get _isVideoMode => _resolvedWorkflowLabel.contains('视频');

  String get _modePrefix =>
      _isProductMode ? '产品灵感模式' : _isWritingMode ? '写作灵感模式' : _isVideoMode ? '视频灵感模式' : '通用灵感模式';

  String get _directoryTitle =>
      _isProductMode ? 'PRD 结构树' : _isWritingMode ? '大纲索引' : _isVideoMode ? '脚本素材' : '素材流';

  String get _directoryDescription =>
      _isProductMode
          ? '围绕用户场景、核心功能与技术点组织当前草稿。'
          : _isWritingMode
              ? '只保留章节和关键词入口，让写作区更沉浸。'
              : _isVideoMode
                  ? '聚合选题、素材片段和画面建议，便于拆成分镜脚本。'
                  : '把当前碎片灵感整理成可继续延展的工作流。';

  List<String> get _localizedSuggestions {
    if (_isProductMode) {
      return const [
        '按用户场景、核心功能、技术点拆成 PRD 初稿',
        '提炼这一页的核心问题、机会点和下一步方案',
        '从产品经理视角检查需求闭环和优先级',
        '把当前草稿改成更像正式方案说明',
      ];
    }
    if (_isWritingMode) {
      return const [
        '按章节整理这份草稿，补一个更顺的结构',
        '润色这一页的语气，让句子更自然',
        '帮我提炼人物、主题和情绪关键词',
        '给这一段补一个更有张力的转折',
      ];
    }
    if (_isVideoMode) {
      return const [
        '把这份内容拆成视频脚本和镜头段落',
        '给每一段补一条画面建议和景别',
        '按节奏整理开场、主体和结尾的脚本',
        '补 3 个适合这条视频的 BGM 气质方向',
      ];
    }
    return const [
      '点击灵感提取，帮我拆出 3 个可扩展方向',
      '提炼这一页的核心冲突和下一步转折',
      '从当前笔记里抽取人物、主题和意象线索',
      '从产品经理视角提炼问题、机会和下一步方案',
    ];
  }

  List<String> get _directoryNodes {
    if (_isProductMode) return const ['用户场景', '核心功能', '技术点'];
    if (_isWritingMode) return const ['开场', '章节推进', '人物线索', '情绪关键词'];
    if (_isVideoMode) return const ['视频主题', '素材片段', '画面建议', 'BGM 气质'];
    return const ['碎片素材', '延展方向', '总结重点'];
  }

  List<String> get _productPortraitTags => const ['产品画像', '用户场景', '关键功能'];

  String _deriveProductPortrait(String rawContent) {
    if (!_isProductMode) return '';
    final normalized = _text(rawContent).trim();
    if (normalized.isEmpty) return '';
    final firstParagraph = normalized.split(RegExp(r'\n\s*\n')).first.trim();
    return firstParagraph.length > 120 ? '${firstParagraph.substring(0, 120)}...' : firstParagraph;
  }

  String _composeWorkspaceContent() {
    final body = _contentCtrl.text.trim();
    if (!_isProductMode) return body;
    final portrait = _productPortraitCtrl.text.trim();
    if (portrait.isEmpty) return body;
    if (body.isEmpty) return '【产品画像】\n$portrait';
    return '【产品画像】\n$portrait\n\n$body';
  }

  void _focusMainEditor() {
    _editorFocusNode.requestFocus();
    if (_editorScrollCtrl.hasClients) {
      _editorScrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollEditorToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_editorScrollCtrl.hasClients) return;
      _editorScrollCtrl.animateTo(
        _editorScrollCtrl.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  void _insertStructureNode(String node) {
    if (_isProductMode && node == '用户场景') {
      _productPortraitFocusNode.requestFocus();
    } else {
      _focusMainEditor();
    }
    final sectionTitle = '【$node】';
    final current = _contentCtrl.text.trimRight();
    if (!current.contains(sectionTitle)) {
      _contentCtrl.text = current.isEmpty ? '$sectionTitle\n' : '$current\n\n$sectionTitle\n';
      _contentCtrl.selection = TextSelection.collapsed(offset: _contentCtrl.text.length);
      _scrollEditorToBottom();
    }
  }

  Future<Map<String, String>?> _authHeaders({bool jsonBody = false}) async {
    final token = await _token();
    if (token == null || token.isEmpty) {
      return null;
    }
    return {
      if (jsonBody) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _fetchAttachments() async {
    try {
      final headers = await _authHeaders();
      if (!mounted || headers == null) return;
      final r = await http.get(
        Uri.parse('$backendUrl/notes/${widget.noteId}/attachments'),
        headers: headers,
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        final list = json.decode(_decodeResponse(r)) as List<dynamic>;
        setState(() {
          _attachments = list
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _uploadAttachment({required String? accept}) async {
    if (_uploadingAttachment) return;
    final messenger = ScaffoldMessenger.of(context);
    final picked = await pickLocalFile(accept: accept);
    if (picked == null) return;
    setState(() => _uploadingAttachment = true);
    try {
      final headers = await _authHeaders(jsonBody: true);
      if (!mounted || headers == null) return;
      final r = await http.post(
        Uri.parse('$backendUrl/notes/${widget.noteId}/attachments'),
        headers: headers,
        body: json.encode({
          'file_name': picked.name,
          'mime_type': picked.mimeType,
          'content_base64': base64Encode(picked.bytes),
        }),
      );
      if (!mounted) return;
      if (r.statusCode == 201) {
        await _fetchAttachments();
        setState(() => _statusNote = '附件已上传，可在 AI 对话中引用。');
        messenger.showSnackBar(SnackBar(content: Text('已上传 ${picked.name}')));
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('上传失败：${r.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('上传失败：$e')));
    } finally {
      if (mounted) {
        setState(() => _uploadingAttachment = false);
      }
    }
  }

  Future<void> _deleteAttachment(Map<String, dynamic> attachment) async {
    final messenger = ScaffoldMessenger.of(context);
    final attachmentId = attachment['id'] as int?;
    if (attachmentId == null) return;
    try {
      final headers = await _authHeaders();
      if (!mounted || headers == null) return;
      final r = await http.delete(
        Uri.parse('$backendUrl/notes/${widget.noteId}/attachments/$attachmentId'),
        headers: headers,
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        await _fetchAttachments();
        setState(() => _statusNote = '附件已移除。');
        messenger.showSnackBar(const SnackBar(content: Text('附件已删除')));
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('删除失败：${r.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('删除失败：$e')));
    }
  }

  Future<void> _transcribeAudioToChat() async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await pickLocalFile(accept: 'audio/*');
    if (picked == null) return;
    setState(() => _uploadingAttachment = true);
    try {
      final headers = await _authHeaders(jsonBody: true);
      if (!mounted || headers == null) return;
      final r = await http.post(
        Uri.parse('$backendUrl/audio/transcribe'),
        headers: headers,
        body: json.encode({
          'mime_type': picked.mimeType,
          'content_base64': base64Encode(picked.bytes),
          'context': '请将语音转成简体中文文本，用于创作记录和 AI 工作台对话。',
        }),
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        final data = json.decode(_decodeResponse(r)) as Map<String, dynamic>;
        final transcript = (data['transcript'] ?? '').toString().trim();
        if (transcript.isNotEmpty) {
          setState(() {
            _chatInputCtrl.text = transcript;
            _chatInputCtrl.selection = TextSelection.collapsed(
              offset: _chatInputCtrl.text.length,
            );
            _statusNote = '语音已转写，可直接发送给 AI。';
          });
          messenger.showSnackBar(const SnackBar(content: Text('语音转写完成')));
        }
      } else {
        messenger.showSnackBar(SnackBar(content: Text('转写失败：${r.statusCode}')));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('转写失败：$e')));
    } finally {
      if (mounted) {
        setState(() => _uploadingAttachment = false);
      }
    }
  }

  Future<void> _bootstrapWorkspace() async {
    setState(() {
      _initializing = true;
      _workspaceError = null;
      _statusNote = null;
    });

    try {
      final headers = await _authHeaders(jsonBody: true);
      if (!mounted) return;
      if (headers == null) {
        setState(() {
          _workspaceError = '登录状态已失效，请重新登录后再进入灵感工作台。';
          _initializing = false;
        });
        return;
      }

      if (widget.conversationId != null) {
        _conversationId = widget.conversationId;
      } else {
        final r = await http.post(
          Uri.parse('$backendUrl/conversations'),
          headers: headers,
          body: json.encode({
            'title': widget.noteTitle.trim().isEmpty ? '灵感工作台会话' : widget.noteTitle,
            'note_id': widget.noteId,
            'workflow_label': widget.workflowLabel,
            'source_note_ids': List.generate(widget.sourceNoteCount, (_) => widget.noteId),
          }),
        );
        if (!mounted) return;

        if (r.statusCode != 200) {
          setState(() {
            _workspaceError = '创建 AI 会话失败：${r.statusCode}';
            _initializing = false;
          });
          return;
        }

        final data = json.decode(_decodeResponse(r)) as Map<String, dynamic>;
        _conversationId = data['id'] as int?;
      }
      await _fetchAttachments();
      _startPolling();
      await _fetchMessages();
      await _fetchWorkspaceHistory();
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _statusNote = widget.conversationId == null
            ? '灵感工作台已连接到真实后端会话。'
            : '已恢复上次的灵感工作台上下文。';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _workspaceError = '初始化灵感工作台失败：$e';
        _initializing = false;
      });
    }
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(milliseconds: 800), (_) => _fetchMessages());
  }

  Future<void> _fetchMessages() async {
    final cid = _conversationId;
    if (cid == null) return;
    try {
      final headers = await _authHeaders();
      if (headers == null) return;
      final r = await http.get(
        Uri.parse('$backendUrl/conversations/$cid/messages'),
        headers: headers,
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        final shouldStick = _autoStickToBottom || !_messageScrollCtrl.hasClients;
        final list = json.decode(_decodeResponse(r)) as List<dynamic>;
        final hasFreshAi = list.isNotEmpty &&
            (list.last as Map<String, dynamic>)['sender']?.toString() == 'ai';
        setState(() {
          _messages = list;
          if (hasFreshAi) {
            _waitingForAi = false;
            _statusNote = 'AI 已返回，可以继续追问或插入正文。';
          }
        });
        if (shouldStick) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchWorkspaceHistory() async {
    try {
      final headers = await _authHeaders();
      if (headers == null) return;
      final r = await http.get(
        Uri.parse('$backendUrl/workspace/history'),
        headers: headers,
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        setState(() => _workspaceHistory = json.decode(_decodeResponse(r)) as List<dynamic>);
      }
    } catch (_) {}
  }

  void _resumeWorkspaceHistoryItem(Map<String, dynamic> item, BuildContext dialogContext) {
    Navigator.pop(dialogContext);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AIWorkspacePage(
          noteId: item['note_id'] as int? ?? widget.noteId,
          noteTitle: _text(item['note_title']),
          noteContent: _text(item['note_content']),
          workflowLabel: _normalizeHistoryWorkflowLabel(
            _text(item['workflow_label']),
            title: _text(item['note_title']),
          ),
          sourceNoteCount: item['source_count'] as int? ?? 1,
          conversationId: item['conversation_id'] as int?,
        ),
      ),
    );
  }

  Future<void> _shareWorkspaceHistoryItem(Map<String, dynamic> item) async {
    final messenger = ScaffoldMessenger.of(context);
    final conversationId = item['conversation_id'] as int?;
    if (conversationId == null) return;
    try {
      final headers = await _authHeaders();
      if (!mounted || headers == null) return;
      final r = await http.post(
        Uri.parse('$backendUrl/workspace/history/$conversationId/share'),
        headers: headers,
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        final body = json.decode(_decodeResponse(r)) as Map<String, dynamic>;
        final shareText = _text(body['share_text']);
        await Clipboard.setData(ClipboardData(text: shareText));
        messenger.showSnackBar(const SnackBar(content: Text('分享文案已复制到剪贴板')));
      } else {
        messenger.showSnackBar(SnackBar(content: Text('分享失败：${r.statusCode}')));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('分享失败：$e')));
    }
  }

  Future<void> _deleteWorkspaceHistoryItem(Map<String, dynamic> item, BuildContext dialogContext) async {
    final messenger = ScaffoldMessenger.of(context);
    final conversationId = item['conversation_id'] as int?;
    if (conversationId == null) return;
    final confirmed = await showDialog<bool>(
          context: dialogContext,
          builder: (confirmCtx) => AlertDialog(
            title: const Text('删除历史灵感'),
            content: const Text('删除后将清理这条工作台上下文，但不会删除原始笔记。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(confirmCtx, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(confirmCtx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: const Text('删除'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      final headers = await _authHeaders();
      if (!mounted || headers == null) return;
      final r = await http.delete(
        Uri.parse('$backendUrl/workspace/history/$conversationId'),
        headers: headers,
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        await _fetchWorkspaceHistory();
        messenger.showSnackBar(const SnackBar(content: Text('历史灵感已删除')));
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.pop(dialogContext);
          await _openWorkspaceHistory();
        }
      } else {
        messenger.showSnackBar(SnackBar(content: Text('删除失败：${r.statusCode}')));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('删除失败：$e')));
    }
  }

  Future<void> _openWorkspaceHistory() async {
    await _fetchWorkspaceHistory();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '历史灵感',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _ink),
                ),
                const SizedBox(height: 8),
                const Text(
                  '可继续编辑未完成草稿，或重新打开之前的灵感工作台上下文。',
                  style: TextStyle(fontSize: 13, color: Color(0xFF60716F), height: 1.6),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _workspaceHistory.isEmpty
                      ? const Center(
                          child: Text('还没有历史灵感草稿。', style: TextStyle(color: Color(0xFF60716F))),
                        )
                      : ListView.separated(
                          itemCount: _workspaceHistory.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: _line.withValues(alpha: 0.85)),
                          itemBuilder: (_, index) {
                            final item = _workspaceHistory[index] as Map<String, dynamic>;
                            final inProgress = (item['status'] ?? '').toString() == 'open';
                            final historyLabel = _normalizeHistoryWorkflowLabel(
                              _text(item['workflow_label']),
                              title: _text(item['note_title']),
                            );
                            final createdAt = _text(item['created_at']);
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 68,
                                    child: Text(
                                      createdAt.length >= 10 ? createdAt.substring(5, 10) : '--',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _HistoryTag(label: historyLabel),
                                            if (inProgress) const _HistoryTag(label: '进行中', active: true),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          _text(item['note_title']).isEmpty ? '未命名草稿' : _text(item['note_title']),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: _ink,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '联合笔记：${item['source_count'] ?? 1} 条',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF60716F)),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            FilledButton(
                                              onPressed: () => _resumeWorkspaceHistoryItem(item, ctx),
                                              style: FilledButton.styleFrom(
                                                backgroundColor: _brand,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              child: const Text('继续编辑'),
                                            ),
                                            const SizedBox(width: 12),
                                            TextButton(
                                              onPressed: () => _shareWorkspaceHistoryItem(item),
                                              style: TextButton.styleFrom(foregroundColor: const Color(0xFF666666)),
                                              child: const Text('分享'),
                                            ),
                                            TextButton(
                                              onPressed: () => _deleteWorkspaceHistoryItem(item, ctx),
                                              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                                              child: const Text('删除'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage({String? preset}) async {
    final cid = _conversationId;
    final messenger = ScaffoldMessenger.of(context);
    final text = _text(preset ?? _chatInputCtrl.text).trim();
    if (cid == null || text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _statusNote = '已发送给 AI，正在结合当前笔记生成回复...';
    });

    try {
      final headers = await _authHeaders(jsonBody: true);
      if (!mounted || headers == null) return;

      final r = await http.post(
        Uri.parse('$backendUrl/conversations/$cid/message'),
        headers: headers,
        body: json.encode({
          'sender': 'user',
          'text': text,
          'note_title': _text(widget.noteTitle),
          'note_content': _composeWorkspaceContent(),
          'attachment_labels': _attachments
              .map((item) {
                final name = (item['file_name'] ?? '').toString();
                final mime = (item['mime_type'] ?? '').toString();
                return mime.isEmpty ? name : '$name ($mime)';
              })
              .where((item) => item.trim().isNotEmpty)
              .toList(),
        }),
      );
      if (!mounted) return;

      if (r.statusCode == 200) {
        _chatInputCtrl.clear();
        setState(() => _waitingForAi = true);
        await _fetchMessages();
        WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
      } else {
        setState(() => _waitingForAi = false);
        messenger.showSnackBar(
          SnackBar(content: Text('AI 请求失败：${r.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _waitingForAi = false);
      messenger.showSnackBar(SnackBar(content: Text('发送失败：$e')));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _saveNoteDraft() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final headers = await _authHeaders(jsonBody: true);
      if (!mounted || headers == null) return;
      final r = await http.patch(
        Uri.parse('$backendUrl/notes/${widget.noteId}'),
        headers: headers,
        body: json.encode({'content': _composeWorkspaceContent()}),
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        setState(() => _statusNote = '当前编辑内容已保存到笔记。');
        messenger.showSnackBar(const SnackBar(content: Text('笔记已保存')));
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('保存失败：${r.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('保存请求失败：$e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _closeAndSummarize() async {
    final cid = _conversationId;
    final messenger = ScaffoldMessenger.of(context);
    if (cid == null || _closing) return;

    setState(() => _closing = true);
    try {
      final headers = await _authHeaders();
      if (!mounted || headers == null) return;
      final r = await http.post(
        Uri.parse('$backendUrl/conversations/$cid/close'),
        headers: headers,
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        final data = json.decode(_decodeResponse(r)) as Map<String, dynamic>;
        final summary = (data['summary'] ?? '').toString();
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('AI 总结'),
            content: SingleChildScrollView(
              child: Text(summary.isEmpty ? '（返回空内容）' : summary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
        setState(() => _statusNote = '会话已总结，摘要已生成到后端。');
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('生成总结失败：${r.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('总结请求失败：$e')));
    } finally {
      if (mounted) {
        setState(() => _closing = false);
      }
    }
  }

  void _insertAssistantText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _contentCtrl.text = '${_contentCtrl.text.trimRight()}\n\n$trimmed';
      _contentCtrl.selection = TextSelection.collapsed(
        offset: _contentCtrl.text.length,
      );
      _statusNote = '已将 AI 内容插入编辑区。';
    });
    _focusMainEditor();
    _scrollEditorToBottom();
  }

  void _backToNotes() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.pushReplacementNamed(context, '/notes');
  }

  String _normalizeHistoryWorkflowLabel(String raw, {String title = ''}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || RegExp(r'^\?+$').hasMatch(trimmed)) {
      if (title.contains('产品')) return '产品灵感';
      if (title.contains('视频') || title.contains('脚本')) return '视频灵感';
      if (title.contains('写作') || title.contains('文章') || title.contains('小说')) {
        return '写作灵感';
      }
      return '通用灵感';
    }
    return trimmed;
  }

  Widget _buildWorkspaceHeader() {
    final title = _text(widget.noteTitle).trim().isEmpty ? '灵感工作台' : _text(widget.noteTitle).trim();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _backToNotes,
            tooltip: '返回主页',
            icon: const Icon(Icons.arrow_back),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _brandDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '[$_modePrefix] $title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusNote ?? '基于当前笔记发起真实 AI 会话，可保存草稿并生成总结。',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF60716F)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _openWorkspaceHistory,
            icon: const Icon(Icons.history, size: 18),
            label: const Text('历史灵感'),
          ),
          SegmentedButton<_WorkspaceLayoutMode>(
            segments: const [
              ButtonSegment<_WorkspaceLayoutMode>(
                value: _WorkspaceLayoutMode.editorFocus,
                icon: Icon(Icons.view_week_outlined, size: 18),
                label: Text('编辑居中'),
              ),
              ButtonSegment<_WorkspaceLayoutMode>(
                value: _WorkspaceLayoutMode.chatFocus,
                icon: Icon(Icons.chat_bubble_outline, size: 18),
                label: Text('对话居中'),
              ),
            ],
            selected: {_layoutMode},
            onSelectionChanged: (selection) {
              setState(() => _layoutMode = selection.first);
            },
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _saving ? null : _saveNoteDraft,
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: const Text('保存草稿'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _closing ? null : _closeAndSummarize,
            icon: _closing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.summarize_outlined, size: 18),
            style: ElevatedButton.styleFrom(
              backgroundColor: _brand,
              foregroundColor: Colors.white,
            ),
            label: const Text('生成总结'),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryPanel() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: _panel.withValues(alpha: 0.45),
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _directoryTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _directoryDescription,
                  style: TextStyle(fontSize: 12, color: Color(0xFF60716F), height: 1.5),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '当前章节',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF60716F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _focusMainEditor,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _text(widget.noteTitle).trim().isEmpty ? '未命名笔记' : _text(widget.noteTitle),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Note ID #${widget.noteId}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF60716F)),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaPill(label: _resolvedWorkflowLabel),
                      if (widget.sourceNoteCount > 1)
                        _MetaPill(label: '整合 ${widget.sourceNoteCount} 条'),
                      ..._directoryNodes.take(3).map((chip) => _MetaPill(label: chip)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isProductMode) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FBF8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PRD 结构树',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._directoryNodes.map(
                            (node) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () => _insertStructureNode(node),
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: _brand,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        node,
                                        style: const TextStyle(fontSize: 13, color: _ink),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FBF8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _line),
                      ),
                      child: const Text(
                        '这里会承接需求截图、竞品资料和方案附件。',
                        style: TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF60716F)),
                      ),
                    ),
                  ] else if (_isWritingMode)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAF8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _line),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _MetaPill(label: '开场'),
                          _MetaPill(label: '人物关系'),
                          _MetaPill(label: '转折'),
                          _MetaPill(label: '文风'),
                        ],
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _uploadingAttachment
                                ? null
                                : () => _uploadAttachment(accept: 'image/*'),
                            icon: const Icon(Icons.image_outlined, size: 16),
                            label: const Text('上传图片'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _uploadingAttachment
                                ? null
                                : () => _uploadAttachment(accept: '*/*'),
                            icon: const Icon(Icons.attach_file_outlined, size: 16),
                            label: const Text('上传文件'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _uploadingAttachment ? null : _transcribeAudioToChat,
                        icon: const Icon(Icons.mic_none_outlined, size: 16),
                        label: const Text('导入音频转写'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _line),
                      ),
                      child: _attachments.isEmpty
                          ? Text(
                              _isProductMode
                                  ? '这里会承接需求截图、竞品资料和方案附件。'
                                  : _isVideoMode
                                      ? '这里会承接脚本资料、画面参考和视频素材说明。'
                                      : '还没有附件。当前版本已支持图片/文件上传；语音输入待接入转写链路。',
                              style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF60716F)),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '当前附件（${_attachments.length}）',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _attachments.map((item) {
                                    final name = (item['file_name'] ?? '').toString();
                                    final mime = (item['mime_type'] ?? '').toString();
                                    return InputChip(
                                      label: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 180),
                                        child: Text(
                                          name.isEmpty ? '未命名附件' : name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      avatar: Icon(
                                        mime.startsWith('image/')
                                            ? Icons.image_outlined
                                            : Icons.insert_drive_file_outlined,
                                        size: 18,
                                      ),
                                      onDeleted: () => _deleteAttachment(item),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '建议指令',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF60716F),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _suggestions.length,
              itemBuilder: (ctx, i) {
                final suggestion = _localizedSuggestions[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => _sendMessage(preset: suggestion),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FBF8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _brand.withValues(alpha: 0.22),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: _brand.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.bolt, size: 14, color: _brandDark),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: _ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorPanel() {
    final title = _text(widget.noteTitle).trim().isEmpty ? '未命名草稿' : _text(widget.noteTitle).trim();
    final maxContentWidth = _isWritingMode ? 760.0 : _isVideoMode ? 1080.0 : 920.0;
    final editorCanvas = Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: _isWritingMode ? 640 : 560),
      padding: EdgeInsets.fromLTRB(_isWritingMode ? 8 : 26, 20, _isWritingMode ? 8 : 26, 32),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFA),
        borderRadius: BorderRadius.circular(_isWritingMode ? 0 : 28),
        border: Border.all(color: _line.withValues(alpha: _isWritingMode ? 0.0 : 0.85)),
        boxShadow: _isWritingMode
            ? const []
            : const [
                BoxShadow(
                  color: Color(0x140B1F17),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
      ),
      child: TextField(
        controller: _contentCtrl,
        focusNode: _editorFocusNode,
        minLines: _isWritingMode ? 22 : 18,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '在这里整理你的草稿、章节、结构和 AI 插入内容...',
        ),
        style: const TextStyle(
          fontFamily: 'Georgia',
          fontSize: 17,
          height: 1.85,
          color: _ink,
        ),
      ),
    );

    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final headerAndBody = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _resolvedWorkflowLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _brandDark,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isProductMode
                    ? '中间区域聚焦产品草稿，右侧负责问题分析、PRD 拆解和方案补全。'
                    : _isWritingMode
                        ? '正文区切到更沉浸的长文模式，右侧负责润色、换词和章节建议。'
                        : _isVideoMode
                            ? '中间区域按文案与画面思路并排整理，右侧负责分镜、节奏与 BGM 建议。'
                            : '中间区域保持沉浸式编辑体验，AI 建议从右侧进入，再由你决定是否纳入正文。',
                style: const TextStyle(fontSize: 13, color: Color(0xFF60716F), height: 1.6),
              ),
              const SizedBox(height: 24),
              if (_isWritingMode)
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 1, color: _line.withValues(alpha: 0.75)),
                        const SizedBox(height: 24),
                        editorCanvas,
                      ],
                    ),
                  ),
                )
              else if (_isVideoMode)
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: SizedBox(
                      width: double.infinity,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(height: 1, color: _line.withValues(alpha: 0.75)),
                                const SizedBox(height: 20),
                                editorCanvas,
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          SizedBox(
                            width: 240,
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FBF8),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: _line),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '画面建议',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink),
                                  ),
                                  SizedBox(height: 10),
                                  Text('分镜 1：开场钩子', style: TextStyle(fontSize: 12, color: Color(0xFF60716F))),
                                  SizedBox(height: 8),
                                  Text('景别：中景 / BGM：轻快推进', style: TextStyle(fontSize: 12, color: _ink)),
                                  SizedBox(height: 16),
                                  Text('分镜 2：主体信息', style: TextStyle(fontSize: 12, color: Color(0xFF60716F))),
                                  SizedBox(height: 8),
                                  Text('景别：特写 / 画面：素材拼贴', style: TextStyle(fontSize: 12, color: _ink)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isProductMode) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _productPortraitTags.map((tag) => _HistoryTag(label: tag)).toList(),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FBF8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '产品画像',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _productPortraitCtrl,
                                  focusNode: _productPortraitFocusNode,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '这里可以继续补充目标用户、使用场景、核心价值和成功指标。',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      height: 1.6,
                                      color: Color(0xFF60716F),
                                    ),
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.6,
                                    color: _ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        Container(height: 1, color: _line.withValues(alpha: 0.75)),
                        const SizedBox(height: 20),
                        editorCanvas,
                      ],
                    ),
                  ),
                ),
            ],
          );

          return Scrollbar(
            controller: _editorScrollCtrl,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _editorScrollCtrl,
              padding: const EdgeInsets.fromLTRB(36, 28, 36, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 60),
                child: headerAndBody,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final sender = (msg['sender'] ?? msg['role'] ?? '').toString();
    final text = _text(msg['text'] ?? '');
    final isUser = sender == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isUser ? _panel : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUser ? _brand.withValues(alpha: 0.22) : _line,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUser ? '\u4f60' : 'AI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isUser ? _brandDark : const Color(0xFF60716F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text.isEmpty ? '\uff08\u7a7a\u6d88\u606f\uff09' : text,
                style: const TextStyle(fontSize: 13, height: 1.6, color: _ink),
              ),
              if (!isUser && text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _insertAssistantText(text),
                    icon: const Icon(Icons.arrow_downward, size: 16),
                    label: const Text('\u63d2\u5165\u6b63\u6587'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF60716F),
                ),
              ),
              SizedBox(height: 6),
              Text(
                '正在结合当前笔记思考...',
                style: TextStyle(fontSize: 13, height: 1.6, color: _ink),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantPanel({double? width}) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F4),
        border: Border(
          left: BorderSide(color: _brand.withValues(alpha: 0.24)),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: _brandDark, size: 20),
                SizedBox(width: 8),
                Text(
                  'AI \u52a9\u624b',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _brand.withValues(alpha: 0.28)),
              ),
              child: _messages.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Text(
                          '还没有消息。你可以从左侧建议指令开始，或者在下方直接向 AI 发起请求。',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF60716F)),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _messageScrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_waitingForAi ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i >= _messages.length) {
                          return _buildTypingBubble();
                        }
                        return _buildMessageBubble(_messages[i] as Map<String, dynamic>);
                      },
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _chatInputCtrl,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        '\u4f8b\u5982\uff1a\u70b9\u51fb\u7075\u611f\u63d0\u53d6\uff0c\u7ed9\u6211 3 \u4e2a\u5ef6\u5c55\u65b9\u5411\u548c\u5efa\u8bae\u5361\u7247',
                    filled: true,
                    fillColor: _paper,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _localizedSuggestions.take(2).map((s) {
                          return ActionChip(
                            label: Text(s, style: const TextStyle(fontSize: 11)),
                            onPressed: _sending ? null : () => _sendMessage(preset: s),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _sending ? null : _sendMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brand,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        icon: _sending
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.send, size: 18),
                        label: const Text('发送'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      appBar: AppBar(title: const Text('灵感工作台')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _workspaceError ?? '灵感工作台初始化失败',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _bootstrapWorkspace,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _backToNotes,
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回主页',
        ),
        title: const Text('灵感工作台'),
        actions: [
          IconButton(
            onPressed: _openWorkspaceHistory,
            icon: const Icon(Icons.history),
            tooltip: '历史灵感',
          ),
          PopupMenuButton<_WorkspaceLayoutMode>(
            tooltip: '版面布局',
            onSelected: (mode) => setState(() => _layoutMode = mode),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _WorkspaceLayoutMode.editorFocus,
                child: Text('编辑居中'),
              ),
              PopupMenuItem(
                value: _WorkspaceLayoutMode.chatFocus,
                child: Text('对话居中'),
              ),
            ],
            icon: const Icon(Icons.dashboard_customize_outlined),
          ),
          IconButton(
            onPressed: _saving ? null : _saveNoteDraft,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
          ),
          IconButton(
            onPressed: _closing ? null : _closeAndSummarize,
            icon: const Icon(Icons.summarize_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildEditorPanel(),
          ),
          SizedBox(
            height: 360,
            child: _buildAssistantPanel(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return _buildLoadingState();
    }
    if (_workspaceError != null) {
      return _buildErrorState();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1350;

    if (!isDesktop) {
      return _buildMobileLayout();
    }

    return Scaffold(
      backgroundColor: _paper,
      body: Column(
        children: [
          _buildWorkspaceHeader(),
          Expanded(
            child: _layoutMode == _WorkspaceLayoutMode.editorFocus
                ? Row(
                    children: [
                      _buildDirectoryPanel(),
                      Expanded(child: _buildEditorPanel()),
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeColumn,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragUpdate: (details) {
                            setState(() {
                              _assistantPanelWidth =
                                  (_assistantPanelWidth - details.delta.dx).clamp(320.0, 620.0);
                            });
                          },
                          child: Container(
                            width: 8,
                            color: Colors.transparent,
                            child: Center(
                              child: Container(
                                width: 3,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: _line,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _buildAssistantPanel(width: _assistantPanelWidth),
                    ],
                  )
                : Row(
                    children: [
                      _buildDirectoryPanel(),
                      Expanded(child: _buildAssistantPanel()),
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeColumn,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragUpdate: (details) {
                            setState(() {
                              _assistantPanelWidth =
                                  (_assistantPanelWidth + details.delta.dx).clamp(360.0, 760.0);
                            });
                          },
                          child: Container(
                            width: 8,
                            color: Colors.transparent,
                            child: Center(
                              child: Container(
                                width: 3,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: _line,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: _assistantPanelWidth, child: _buildEditorPanel()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;

  const _MetaPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFC6D6CD)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: _AIWorkspacePageState._ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HistoryTag extends StatelessWidget {
  final String label;
  final bool active;

  const _HistoryTag({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE7F5EC) : const Color(0xFFF2F5F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: active ? _AIWorkspacePageState._brand : _AIWorkspacePageState._brandDark,
        ),
      ),
    );
  }
}
