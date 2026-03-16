import 'dart:convert';
import 'dart:html' as html;

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
  static const Color _brandDark = Color(0xFF214C37);
  static const Color _paper = Color(0xFFF3F7F1);
  static const Color _line = Color(0xFFDDE7DA);
  static const Color _muted = Color(0xFF60716F);
  static const Color _ink = Color(0xFF22302C);

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
      fillColor: Colors.white,
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

  void _openExternalLink(String url) {
    html.window.open(url, '_blank');
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

  Widget _buildNavRail() {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1EA),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'API 导航',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '先把常用连接集中到左侧，后续增加更多接口时会更容易扩展。',
            style: TextStyle(fontSize: 13, color: _muted, height: 1.6),
          ),
          const SizedBox(height: 20),
          _buildNavItem(
            icon: Icons.api_outlined,
            title: 'Notion API',
            subtitle: '当前可配置',
            selected: true,
          ),
          const SizedBox(height: 12),
          _buildNavItem(
            icon: Icons.chat_outlined,
            title: 'AI Provider',
            subtitle: '后续接入',
          ),
          const SizedBox(height: 12),
          _buildNavItem(
            icon: Icons.cloud_sync_outlined,
            title: '同步接口',
            subtitle: '预留',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool selected = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? _brand.withValues(alpha: 0.35) : _line),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected ? _brand.withValues(alpha: 0.12) : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: selected ? _brandDark : _muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.api_outlined, color: _brandDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notion API 连接',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _connected ? '当前状态：已连接' : '当前状态：未连接',
                      style: const TextStyle(fontSize: 14, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            '填写你的 Notion Integration Token 和目标 Database ID。当前阶段先保存连接配置，后续再继续接入真正同步和写入。',
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
    );
  }

  Widget _buildGuideCard() {
    return SelectionArea(
      child: Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '操作手册',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '1. 如何找到 Integration Token',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 6),
          const Text(
            '进入 Notion 的 My integrations 页面，创建或打开一个 Integration，在 Secrets 区域复制 Internal Integration Token。',
            style: TextStyle(fontSize: 14, color: _muted, height: 1.7),
          ),
          const SizedBox(height: 10),
          _GuideLinkTile(
            label: '官方入口：My integrations',
            url: 'https://www.notion.so/profile/integrations',
            onTap: _openExternalLink,
          ),
          const SizedBox(height: 16),
          const Text(
            '2. 如何找到 Database ID',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 6),
          const Text(
            '打开你的目标数据库页面，复制浏览器地址栏中数据库链接的一长串 ID；如果链接中带有查询参数，只取中间那段主 ID。',
            style: TextStyle(fontSize: 14, color: _muted, height: 1.7),
          ),
          const SizedBox(height: 10),
          _GuideLinkTile(
            label: '官方文档：Working with databases',
            url: 'https://developers.notion.com/docs/working-with-databases',
            onTap: _openExternalLink,
          ),
          const SizedBox(height: 16),
          const Text(
            '3. 授权数据库给 Integration',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 6),
          const Text(
            '回到 Notion 数据库页面，点击右上角 Share，把刚创建的 Integration 添加进去，否则即使保存了 Token 和 Database ID，后续也无法真正同步。',
            style: TextStyle(fontSize: 14, color: _muted, height: 1.7),
          ),
          const SizedBox(height: 10),
          _GuideLinkTile(
            label: '官方文档：Create your first integration',
            url: 'https://developers.notion.com/docs/create-a-notion-integration',
            onTap: _openExternalLink,
          ),
          const SizedBox(height: 10),
          _GuideLinkTile(
            label: '官方文档：Authorization',
            url: 'https://developers.notion.com/docs/authorization',
            onTap: _openExternalLink,
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FAF7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _line),
            ),
            child: const Text(
              '如果网页内不能直接点开，也可以复制上面的官方链接到浏览器打开。',
              style: TextStyle(fontSize: 13, color: _muted, height: 1.6),
            ),
          ),
        ],
      ),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        surfaceTintColor: Colors.transparent,
        title: const Text('API连接'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1100;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildNavRail(),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildConfigCard(),
                                      const SizedBox(height: 20),
                                      _buildGuideCard(),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildConfigCard(),
                                const SizedBox(height: 20),
                                _buildGuideCard(),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _GuideLinkTile extends StatelessWidget {
  final String label;
  final String url;
  final void Function(String url) onTap;

  const _GuideLinkTile({
    required this.label,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(url),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6FAF7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDDE7DA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.open_in_new_outlined, size: 16, color: Color(0xFF214C37)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '官方链接',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF214C37),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const SizedBox.shrink(),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF22302C),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              url,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF60716F),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
