import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const backendUrl = String.fromEnvironment('BACKEND_URL', defaultValue: 'http://10.0.2.2:8000');

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<dynamic> _messages = [];
  final TextEditingController _ctrl = TextEditingController();
  Timer? _poller;
  bool _sending = false;
  bool _closing = false;
  int? _conversationId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _poller?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 1), (_) => _fetchMessages());
  }

  Future<void> _fetchMessages() async {
    final cid = _conversationId;
    if (cid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final r = await http.get(
        Uri.parse('$backendUrl/conversations/$cid/messages'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (r.statusCode == 200) {
        final list = json.decode(r.body) as List<dynamic>;
        setState(() => _messages = list);
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final cid = _conversationId;
    final text = _ctrl.text.trim();
    if (cid == null || text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final r = await http.post(
        Uri.parse('$backendUrl/conversations/$cid/message'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'sender': 'user', 'text': text}),
      );
      if (r.statusCode == 200) {
        _ctrl.clear();
        await _fetchMessages();
      }
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _closeAndSummarize() async {
    final cid = _conversationId;
    if (cid == null || _closing) return;
    setState(() => _closing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final r = await http.post(
        Uri.parse('$backendUrl/conversations/$cid/close'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (r.statusCode == 200) {
        final data = json.decode(r.body) as Map<String, dynamic>;
        final summary = (data['summary'] ?? '').toString();
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('AI Summary'),
            content: SingleChildScrollView(
              child: Text(summary.isEmpty ? '(empty summary)' : summary),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ],
          ),
        );
        await _fetchMessages();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Summary failed: ${r.statusCode}')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Summary request failed')),
      );
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_conversationId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        _conversationId = args;
        _fetchMessages();
        _startPolling();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat - ${_conversationId ?? ''}'),
        actions: [
          IconButton(
            onPressed: _closing ? null : _closeAndSummarize,
            icon: _closing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.summarize),
            tooltip: 'Generate summary',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i] as Map<String, dynamic>;
                final isUser = (m['sender'] ?? '') == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue.shade200 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text((m['text'] ?? '').toString()),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(hintText: 'Type a message'),
                    ),
                  ),
                ),
                _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator()),
                      )
                    : IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
