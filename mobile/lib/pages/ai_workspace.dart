import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AIWorkspacePage extends StatefulWidget {
  final int noteId;
  final String noteTitle;
  final String noteContent;

  const AIWorkspacePage({
    Key? key,
    required this.noteId,
    required this.noteTitle,
    required this.noteContent,
  }) : super(key: key);

  @override
  State<AIWorkspacePage> createState() => _AIWorkspacePageState();
}

class _AIWorkspacePageState extends State<AIWorkspacePage> {
  late TextEditingController _contentCtrl;
  late TextEditingController _chatInputCtrl;

  List<Map<String, dynamic>> _messages = [];
  List<String> _suggestions = [
    '继续这个故事，加入更多悬念',
    '改进这段文字的流畅度',
    '建议下一个情节转折',
  ];
  bool _loading = false;
  String? _selectedChapter;

  final List<Map<String, String>> _chapters = [
    {'id': '1', 'title': '第一章：AI的觉醒'},
    {'id': '2', 'title': '第二章：初次对话'},
    {'id': '3', 'title': '第三章：深度思考'},
  ];

  @override
  void initState() {
    super.initState();
    _contentCtrl = TextEditingController(text: widget.noteContent);
    _chatInputCtrl = TextEditingController();
    _selectedChapter = '2';
    _initSampleMessages();
  }

  void _initSampleMessages() {
    _messages = [
      {
        'role': 'assistant',
        'text': '你好！我是你的AI写作助手。我可以帮你继续这个故事、改进文字，或给出创意建议。',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 2)),
      },
      {
        'role': 'user',
        'text': '帮我把这一段的语气改得更悬念一些',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 1)),
      },
      {
        'role': 'assistant',
        'text': '我已经为你生成了几个续写版本。你可以选择其中一个，或告诉我具体想要的风格。',
        'timestamp': DateTime.now(),
      },
    ];
  }

  void _sendMessage() {
    if (_chatInputCtrl.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'role': 'user',
        'text': _chatInputCtrl.text,
        'timestamp': DateTime.now(),
      });
      _chatInputCtrl.clear();
      _loading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'text': 'AI 已根据你的要求生成了续写方案。请查看下方候选片段。',
            'timestamp': DateTime.now(),
          });
          _loading = false;
        });
      }
    });
  }

  void _insertContent(String suggestion) {
    _contentCtrl.text += '\n\n$suggestion';
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _chatInputCtrl.dispose();
    super.dispose();
  }

  Widget _buildChapterList() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '项目目录',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI的觉醒',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _chapters.length,
              itemBuilder: (ctx, i) {
                final ch = _chapters[i];
                final isSelected = _selectedChapter == ch['id'];
                return ListTile(
                  selected: isSelected,
                  selectedTileColor: Colors.blue.withOpacity(0.1),
                  title: Text(
                    ch['title']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  onTap: () {
                    setState(() => _selectedChapter = ch['id']);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            'Chapter 2: First Conversation',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: TextField(
              controller: _contentCtrl,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '在此编辑内容...',
              ),
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 16,
                height: 1.8,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIPanel() {
    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // AI Assistant header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 20, color: Color(0xFF388E3C)),
                const SizedBox(width: 8),
                const Text(
                  'AI 助手',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          ),

          // Chat window
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) {
                  final msg = _messages[i];
                  final isUser = msg['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      constraints: const BoxConstraints(maxWidth: 280),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            isUser ? Colors.green[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg['text'] as String,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Chat input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatInputCtrl,
                    decoration: InputDecoration(
                      hintText: '输入要求...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _loadingstate,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: const Color(0xFF388E3C),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 0.5,
            color: Colors.grey[300],
          ),

          // Suggestions
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '生成的续写选项',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ..._suggestions.map((sugg) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sugg,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 28,
                                    child: ElevatedButton(
                                      onPressed: () => _insertContent(sugg),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF388E3C),
                                      ),
                                      child: const Text(
                                        '插入',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: SizedBox(
                                    height: 28,
                                    child: OutlinedButton(
                                      onPressed: () {},
                                      child: const Text(
                                        '重新生成',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
    final isDesktop = screenWidth >= 1400;

    if (!isDesktop) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI 工作台')),
        body: _buildEditor(),
      );
    }

    // Desktop 3-column layout
    return Scaffold(
      body: Row(
        children: [
          _buildChapterList(),
          Expanded(child: _buildEditor()),
          _buildAIPanel(),
        ],
      ),
    );
  }

  void _loadingstate() => _sendMessage();
}
