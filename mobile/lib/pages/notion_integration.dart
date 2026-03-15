import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class NotionIntegrationPage extends StatefulWidget {
  const NotionIntegrationPage({super.key});

  @override
  State<NotionIntegrationPage> createState() => _NotionIntegrationPageState();
}

class _NotionIntegrationPageState extends State<NotionIntegrationPage> {
  static const Color _brand = Color(0xFF388E3C);
  static const Color _brandDark = Color(0xFF2E7D32);
  static const Color _paper = Color(0xFFFAFBFC);
  static const Color _line = Color(0xFFDDE7DA);
  static const Color _muted = Color(0xFF60716F);

  final _tokenCtrl = TextEditingController();
  final _databaseCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _obscureToken = true;
  String? _error;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _loadIntegration();
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _databaseCtrl.dispose();
    super.dispose();
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  String _decodeResponse(http.Response response) {
    return utf8.decode(response.bodyBytes);
  }

  InputDecoration _decoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _brand, width: 1.4),
      ),
    );
  }

  Future<void> _loadIntegration() async {
    final accessToken = await _token();
    if (accessToken == null || accessToken.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '登录状态已失效，请重新登录。';
      });
      return;
    }

    try {
      final resp = await http.get(
        Uri.parse('$backendUrl/integrations/notion'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = json.decode(_decodeResponse(resp)) as Map<String, dynamic>;
        _tokenCtrl.text = data['api_token']?.toString() ?? '';
        _databaseCtrl.text = data['database_id']?.toString() ?? '';
        setState(() {
          _connected = data['connected'] == true;
          _error = null;
        });
      } else {
        setState(() => _error = '加载 Notion 配置失败：${resp.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '网络错误：$e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveIntegration() async {
    final accessToken = await _token();
    if (!mounted || accessToken == null || accessToken.isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final resp = await http.put(
        Uri.parse('$backendUrl/integrations/notion'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'api_token': _tokenCtrl.text.trim().isEmpty ? null : _tokenCtrl.text.trim(),
          'database_id': _databaseCtrl.text.trim().isEmpty ? null : _databaseCtrl.text.trim(),
        }),
      );

      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = json.decode(_decodeResponse(resp)) as Map<String, dynamic>;
        setState(() => _connected = data['connected'] == true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notion API 连接已保存')),
        );
      } else {
        setState(() => _error = '保存失败：${resp.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '保存失败：$e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F7F1),
        surfaceTintColor: Colors.transparent,
        title: const Text('API连接'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Container(
                    padding: const EdgeInsets.all(28),
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
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _brand.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.api_outlined, color: _brandDark),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Notion API 连接',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _connected ? '当前状态：已连接' : '当前状态：未连接',
                                  style: const TextStyle(color: _muted),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '填写你的 Notion Integration Token 和目标 Database ID。当前 MVP 先保存连接配置，后续可继续接入同步与写入能力。',
                          style: TextStyle(fontSize: 14, color: _muted, height: 1.7),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _tokenCtrl,
                          obscureText: _obscureToken,
                          decoration: _decoration(
                            label: 'Integration Token',
                            hint: 'secret_xxx',
                            prefixIcon: const Icon(Icons.key_outlined),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscureToken = !_obscureToken),
                              icon: Icon(
                                _obscureToken ? Icons.visibility_off : Icons.visibility,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _databaseCtrl,
                          decoration: _decoration(
                            label: 'Database ID',
                            hint: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                            prefixIcon: const Icon(Icons.table_chart_outlined),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFFC9C9)),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Color(0xFFB42318), height: 1.5),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _saving ? null : _loadIntegration,
                                icon: const Icon(Icons.refresh),
                                label: const Text('重新读取'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: _brand,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _saving ? null : _saveIntegration,
                                icon: _saving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined),
                                label: const Text('保存连接'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
