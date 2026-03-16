import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

enum _SettingsSection { profile, style, api, provider }

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Color _brand = Color(0xFF2D6A4F);
  static const Color _brandDark = Color(0xFF1A3C34);
  static const Color _paper = Color(0xFFF4F7F4);
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
  _SettingsSection _selectedSection = _SettingsSection.profile;

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

  Widget _detailCard({
    required String title,
    required String subtitle,
    required Widget child,
    required IconData icon,
  }) {
    return Container(
      key: ValueKey(_selectedSection.name),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 820),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100E1A13),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
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
                child: Icon(icon, color: _brandDark, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 14, color: _muted, height: 1.7),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
                Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
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

    return _detailCard(
      title: '个人资料',
      subtitle: '统一管理绑定邮箱、手机、职业标签等账号基础信息。',
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
    return _detailCard(
      title: '风格',
      subtitle: '管理你的界面风格偏好。当前先保存在本地，后续再同步到账户。',
      icon: Icons.palette_outlined,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: styles.map((style) {
          return ChoiceChip(
            label: Text(style),
            selected: _selectedStyle == style,
            onSelected: (_) => _saveStylePreference(style),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildApiSection() {
    return _detailCard(
      title: 'API',
      subtitle: '真正的接口配置统一收进设置页，文档说明单独放在 API 文档页。',
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
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/notion-integration'),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('查看 API 文档'),
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
    return _detailCard(
      title: 'AI Provider',
      subtitle: '当前由服务端统一配置，后续可扩展为按用户选择 Provider、模型和密钥。',
      icon: Icons.smart_toy_outlined,
      child: Column(
        children: [
          _infoTile(icon: Icons.hub_outlined, label: '当前模式', value: '服务端统一 Provider'),
          const SizedBox(height: 12),
          _infoTile(icon: Icons.tune_outlined, label: '可扩展项', value: 'Provider / Model / Key / 配额'),
        ],
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case _SettingsSection.profile:
        return _buildProfileSection();
      case _SettingsSection.style:
        return _buildStyleSection();
      case _SettingsSection.api:
        return _buildApiSection();
      case _SettingsSection.provider:
        return _buildProviderSection();
    }
  }

  Widget _buildSidebarItem({
    required _SettingsSection section,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _selectedSection == section;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _selectedSection = section),
        borderRadius: BorderRadius.circular(20),
        hoverColor: _brand.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? _brandDark : Colors.white.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _brandDark : _line,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.14) : _brand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : _brandDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : _ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: selected ? Colors.white70 : _muted,
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
  }

  Widget _buildSidebar() {
    final email = _userInfo?['email']?.toString() ?? '当前账号';
    final identity = _userInfo?['identity']?.toString().trim();
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(30),
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
                  color: _brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.settings_outlined, color: _brandDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '设置中心',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (identity == null || identity.isEmpty) ? email : '$email · $identity',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _muted, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSidebarItem(
            section: _SettingsSection.profile,
            title: '个人资料',
            subtitle: '邮箱、手机、职业标签',
            icon: Icons.person_outline,
          ),
          _buildSidebarItem(
            section: _SettingsSection.style,
            title: '风格',
            subtitle: '主题风格与视觉偏好',
            icon: Icons.palette_outlined,
          ),
          _buildSidebarItem(
            section: _SettingsSection.api,
            title: 'API',
            subtitle: 'Notion Token 与 Database ID',
            icon: Icons.api_outlined,
          ),
          _buildSidebarItem(
            section: _SettingsSection.provider,
            title: 'AI Provider',
            subtitle: 'Provider、模型与配额规划',
            icon: Icons.smart_toy_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSidebar(),
              const SizedBox(width: 24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOut,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: _buildSectionContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _buildSidebar(),
          const SizedBox(height: 18),
          _buildSectionContent(),
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
                    if (constraints.maxWidth >= 980) {
                      return _buildDesktopLayout();
                    }
                    return _buildMobileLayout();
                  },
                ),
    );
  }
}
