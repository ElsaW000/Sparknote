import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Color _brand = Color(0xFF2D6A4F);
  static const Color _brandDark = Color(0xFF1A3C34);
  static const Color _paper = Color(0xFFF3F7F1);
  static const Color _line = Color(0xFFDDE7DA);
  static const Color _muted = Color(0xFF60716F);
  static const Color _ink = Color(0xFF22302C);
  static const String _stylePrefKey = 'ui_style_preference';

  final TextEditingController _tokenCtrl = TextEditingController();
  final TextEditingController _databaseCtrl = TextEditingController();

  Map<String, dynamic>? _userInfo;
  bool _loading = true;
  bool _savingIntegration = false;
  bool _obscureToken = true;
  String? _error;
  bool _connected = false;
  String _selectedStyle = '沉静绿洲';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _databaseCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedStyle = prefs.getString(_stylePrefKey) ?? _selectedStyle;
    await Future.wait([_fetchUserInfo(), _loadIntegration()]);
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  String _decodeResponse(http.Response response) {
    return utf8.decode(response.bodyBytes);
  }

  Future<void> _fetchUserInfo() async {
    try {
      final token = await _token();
      if (token == null || token.isEmpty) {
        _error = '登录状态已失效，请重新登录。';
        return;
      }

      final r = await http.get(
        Uri.parse('$backendUrl/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (r.statusCode == 200) {
        _userInfo = json.decode(_decodeResponse(r)) as Map<String, dynamic>;
      } else {
        _error = '加载用户信息失败：${r.statusCode}';
      }
    } catch (e) {
      _error = '网络请求失败：$e';
    }
  }

  Future<void> _loadIntegration() async {
    try {
      final token = await _token();
      if (token == null || token.isEmpty) return;

      final resp = await http.get(
        Uri.parse('$backendUrl/integrations/notion'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (resp.statusCode == 200) {
        final data = json.decode(_decodeResponse(resp)) as Map<String, dynamic>;
        _tokenCtrl.text = data['api_token']?.toString() ?? '';
        _databaseCtrl.text = data['database_id']?.toString() ?? '';
        _connected = data['connected'] == true;
      }
    } catch (_) {}
  }

  Future<void> _saveIntegration() async {
    final token = await _token();
    if (!mounted || token == null || token.isEmpty) return;

    setState(() => _savingIntegration = true);
    try {
      final resp = await http.put(
        Uri.parse('$backendUrl/integrations/notion'),
        headers: {
          'Authorization': 'Bearer $token',
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
          const SnackBar(content: Text('API 对接配置已保存到设置页')),
        );
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
    } finally {
      if (mounted) {
        setState(() => _savingIntegration = false);
      }
    }
  }

  Future<void> _saveStylePreference(String style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stylePrefKey, style);
    if (!mounted) return;
    setState(() => _selectedStyle = style);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已切换界面风格：$style')),
    );
  }

  InputDecoration _fieldDecoration({
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

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              if (icon != null) ...[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _brand.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: _brandDark, size: 20),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: _muted, height: 1.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Icon(icon, color: _brandDark, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    final email = _userInfo?['email']?.toString() ?? '未获取';
    final identity = _userInfo?['identity']?.toString().trim();
    final createdAt = _userInfo?['created_at']?.toString() ?? '未获取';

    return _sectionCard(
      title: '个人资料',
      subtitle: '集中展示你的账号身份、绑定状态和基础职业标签。',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _infoTile(icon: Icons.email_outlined, label: '绑定邮箱', value: email),
          const SizedBox(height: 12),
          _infoTile(icon: Icons.phone_android_outlined, label: '绑定手机', value: '暂未支持'),
          const SizedBox(height: 12),
          _infoTile(
            icon: Icons.badge_outlined,
            label: '职业标签',
            value: (identity == null || identity.isEmpty) ? '未设置' : identity,
          ),
          const SizedBox(height: 12),
          _infoTile(icon: Icons.schedule_outlined, label: '注册时间', value: createdAt),
        ],
      ),
    );
  }

  Widget _buildStyleSection() {
    const styles = ['沉静绿洲', '清透纸感', '深色专注'];
    return _sectionCard(
      title: '风格',
      subtitle: '这里放你的界面风格偏好。当前先保存本地偏好，后续再同步到账户。',
      icon: Icons.palette_outlined,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: styles.map((style) {
          final selected = _selectedStyle == style;
          return ChoiceChip(
            label: Text(style),
            selected: selected,
            onSelected: (_) => _saveStylePreference(style),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildApiSection() {
    return _sectionCard(
      title: 'API',
      subtitle: '把真正的对接配置收进设置页，操作文档则单独放到 API 文档页。',
      icon: Icons.api_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _connected ? '当前状态：Notion 已连接' : '当前状态：Notion 未连接',
              style: const TextStyle(
                fontSize: 13,
                color: _ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tokenCtrl,
            obscureText: _obscureToken,
            decoration: _fieldDecoration(
              label: 'Notion Integration Token',
              hint: 'secret_xxx',
              prefixIcon: const Icon(Icons.key_outlined),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureToken = !_obscureToken),
                icon: Icon(_obscureToken ? Icons.visibility_off : Icons.visibility),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _databaseCtrl,
            decoration: _fieldDecoration(
              label: 'Database ID',
              hint: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
              prefixIcon: const Icon(Icons.table_chart_outlined),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/notion-integration'),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('查看操作文档'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _savingIntegration ? null : _saveIntegration,
                  icon: _savingIntegration
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('保存 API 配置'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSection() {
    return _sectionCard(
      title: 'AI Provider',
      subtitle: '当前由服务端统一配置，后续可以扩展为按用户选择 provider、模型和密钥。',
      icon: Icons.smart_toy_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoTile(icon: Icons.hub_outlined, label: '当前模式', value: '服务端统一 Provider'),
          const SizedBox(height: 12),
          _infoTile(icon: Icons.tune_outlined, label: '可扩展项', value: 'Provider / Model / Key / 配额'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(title: const Text('设置')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
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
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildProfileSection(),
                                          const SizedBox(height: 20),
                                          _buildApiSection(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildStyleSection(),
                                          const SizedBox(height: 20),
                                          _buildProviderSection(),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildProfileSection(),
                                    const SizedBox(height: 20),
                                    _buildStyleSection(),
                                    const SizedBox(height: 20),
                                    _buildApiSection(),
                                    const SizedBox(height: 20),
                                    _buildProviderSection(),
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
