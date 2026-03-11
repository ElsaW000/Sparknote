import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class NoteDetailPage extends StatefulWidget {
  final Map<String, dynamic> note;

  const NoteDetailPage({Key? key, required this.note}) : super(key: key);

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  List<dynamic> _relatedNotes = [];
  bool _loadingRelated = false;
  String? _relatedError;

  @override
  void initState() {
    super.initState();
    _fetchRelatedNotes();
  }

  Future<void> _fetchRelatedNotes() async {
    setState(() {
      _loadingRelated = true;
      _relatedError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null || token.isEmpty) {
        setState(() => _relatedError = '登录状态已失效');
        return;
      }

      final r = await http.get(
        Uri.parse('$backendUrl/notes/${widget.note['id']}/related'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (r.statusCode == 200) {
        final list = json.decode(r.body) as List<dynamic>;
        setState(() => _relatedNotes = list);
      } else {
        setState(() => _relatedError = '加载相关笔记失败：${r.statusCode}');
      }
    } catch (e) {
      setState(() => _relatedError = '网络请求失败：$e');
    } finally {
      setState(() => _loadingRelated = false);
    }
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _createRelation(int targetNoteId, String relationType) async {
    final token = await _token();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登录状态已失效，请重新登录')),
      );
      return;
    }

    try {
      final r = await http.post(
        Uri.parse('$backendUrl/notes/${widget.note['id']}/relations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'to_note_id': targetNoteId,
          'relation_type': relationType,
        }),
      );

      if (r.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('关系创建成功')),
        );
        await _fetchRelatedNotes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建关系失败：${r.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('网络请求失败：$e')),
      );
    }
  }

  Future<void> _deleteRelation(int relationId) async {
    final token = await _token();
    if (token == null || token.isEmpty) return;

    try {
      final r = await http.delete(
        Uri.parse('$backendUrl/notes/${widget.note['id']}/relations/$relationId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (r.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('关系删除成功')),
        );
        await _fetchRelatedNotes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除关系失败：${r.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('网络请求失败：$e')),
      );
    }
  }

  void _showCreateRelationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('创建笔记关系'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('相关'),
              subtitle: const Text('两个笔记内容相关'),
              onTap: () {
                Navigator.pop(ctx);
                _showNoteSelector('related');
              },
            ),
            ListTile(
              title: const Text('父子关系'),
              subtitle: const Text('当前笔记是父笔记'),
              onTap: () {
                Navigator.pop(ctx);
                _showNoteSelector('parent');
              },
            ),
            ListTile(
              title: const Text('引用'),
              subtitle: const Text('当前笔记引用了其他笔记'),
              onTap: () {
                Navigator.pop(ctx);
                _showNoteSelector('reference');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Future<void> _showNoteSelector(String relationType) async {
    // 获取所有笔记用于选择
    List<dynamic> allNotes = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null || token.isEmpty) return;

      final r = await http.get(
        Uri.parse('$backendUrl/notes'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (r.statusCode == 200) {
        allNotes = json.decode(r.body) as List<dynamic>;
        // 过滤掉当前笔记
        allNotes = allNotes.where((n) => n['id'] != widget.note['id']).toList();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载笔记列表失败：$e')),
      );
      return;
    }

    if (allNotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有其他笔记可以关联')),
      );
      return;
    }

    final selectedNote = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择要关联的笔记'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: allNotes.length,
            itemBuilder: (ctx, i) {
              final note = allNotes[i] as Map<String, dynamic>;
              return ListTile(
                title: Text(note['title'] ?? '未命名'),
                subtitle: Text(
                  (note['content'] ?? '').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.pop(ctx, note),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (selectedNote != null) {
      await _createRelation(selectedNote['id'], relationType);
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final tags = (note['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(note['title'] ?? '笔记详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: '创建关系',
            onPressed: _showCreateRelationDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 笔记内容
            if (note['title'] != null && note['title'].toString().isNotEmpty)
              Text(
                note['title'],
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            const SizedBox(height: 8),
            Text(
              note['content'] ?? '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),

            // 标签
            if (tags.isNotEmpty) ...[
              Text(
                '标签',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((tag) => Chip(label: Text(tag))).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 创建时间
            Text(
              '创建时间: ${note['created_at'] ?? '未知'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),

            // 相关笔记
            Row(
              children: [
                Text(
                  '相关笔记',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchRelatedNotes,
                  tooltip: '刷新',
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_loadingRelated)
              const Center(child: CircularProgressIndicator())
            else if (_relatedError != null)
              Center(child: Text(_relatedError!))
            else if (_relatedNotes.isEmpty)
              const Center(child: Text('暂无相关笔记'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _relatedNotes.length,
                itemBuilder: (ctx, i) {
                  final related = _relatedNotes[i] as Map<String, dynamic>;
                  final relationId = related['relation_id'];
                  final relationType = related['relation_type'];
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(related['title'] ?? '未命名'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('相关度: ${related['score']}'),
                          if (relationType != null)
                            Text('关系: $relationType', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: relationId != null ? IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteRelation(relationId),
                      ) : null,
                      onTap: () {
                        // 导航到相关笔记详情
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => NoteDetailPage(note: related),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}