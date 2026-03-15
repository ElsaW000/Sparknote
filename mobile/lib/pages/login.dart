import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'immersion_scene.dart';

const Color _authBg = Color(0xFF1A3C34);
const Color _authBrand = Color(0xFF2D6A4F);
const Color _authMint = Color(0xFFD8E2DC);
const Color _authText = Color(0xFFFFFFFF);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const List<_PersonaOption> _personaOptions = [
    _PersonaOption(
      label: '小说作者',
      accent: Color(0xFF2D6A4F),
      icon: Icons.menu_book_outlined,
      sceneTitle: '如果你是小说作者：',
      sceneSubtitle: '把稍纵即逝的人物、冲突和氛围感留住。',
      sceneDescription:
          'Sparknote 帮你把零散灵感先收集，再逐步延展成角色线、章节提纲和可以继续写下去的长文本结构。',
      tags: ['#人物设定', '#章节大纲', '#世界观', '#灵感碎片'],
    ),
    _PersonaOption(
      label: '产品经理',
      accent: Color(0xFF3B7560),
      icon: Icons.insights_outlined,
      sceneTitle: '如果你是产品经理：',
      sceneSubtitle: '把访谈线索、需求判断和方案方向串成闭环。',
      sceneDescription:
          '从灵感和观察出发，快速沉淀问题定义、用户洞察、功能方向，再让 AI 协助整理成结构化方案。',
      tags: ['#用户洞察', '#需求分析', '#功能拆解', '#方案草图'],
    ),
    _PersonaOption(
      label: '内容创作者',
      accent: Color(0xFF4A8A64),
      icon: Icons.movie_creation_outlined,
      sceneTitle: '如果你是内容创作者：',
      sceneSubtitle: '快速捕捉碎片念头，不丢失每一刻素材。',
      sceneDescription:
          'Sparknote 可以把标题灵感、脚本线索、选题角度和表达方式快速收拢，再整理成可发布的内容结构。',
      tags: ['#小红书', '#公众号', '#短视频', '#创意脚本'],
    ),
    _PersonaOption(
      label: '全场景创作',
      accent: Color(0xFF5D7F71),
      icon: Icons.explore_outlined,
      sceneTitle: '如果你需要全场景创作：',
      sceneSubtitle: '让记录、提炼和延展在一个工作流里连起来。',
      sceneDescription:
          '无论是写作、产品还是内容表达，你都可以先快速记录，再逐步进入结构化的灵感工作台。',
      tags: ['#灵感管理', '#结构提炼', '#AI工作台', '#多场景记录'],
    ),
  ];

  static const List<Map<String, String>> _demoAccounts = [
    {'label': '测试账号', 'email': 'tester@example.com', 'password': 'pass1234'},
    {'label': '备用账号', 'email': 'test@example.com', 'password': 'test123'},
  ];

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  static final RegExp _emailPattern =
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = '邮箱和密码不能为空');
      return;
    }
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = '请输入有效的邮箱地址');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('$backendUrl/auth/login');
      final r = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      if (r.statusCode == 200) {
        final data = json.decode(r.body) as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        if (token == null || token.isEmpty) {
          setState(() => _error = '登录响应异常：缺少 token');
          return;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/notes');
      } else {
        setState(() => _error = '登录失败：${_readErrorDetail(r.body, r.statusCode)}');
      }
    } catch (e) {
      // Flutter web wraps HTTP calls in XMLHttpRequest. A generic
      // "XMLHttpRequest error" means the client couldn't reach the
      // backend or the browser blocked the request (CORS). During
      // development this usually means the server isn't running or
      // the BACKEND_URL is wrong.
      if (e is http.ClientException) {
        setState(() => _error =
            '无法连接到服务器，请检查 BACKEND_URL 和后端是否在运行');
      } else {
        setState(() => _error = '请求异常：$e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _readErrorDetail(String rawBody, int statusCode) {
    try {
      final body = json.decode(rawBody);
      if (body is Map<String, dynamic>) {
        final detail = body['detail']?.toString();
        if (detail != null && detail.isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {}
    return 'HTTP $statusCode';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _fillDemoAccount(String email, String password) {
    setState(() {
      _emailCtrl.text = email;
      _passwordCtrl.text = password;
      _error = null;
    });
  }

  void _openImmersionScene(_PersonaOption option) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ImmersionScenePage(
          title: option.sceneTitle,
          subtitle: option.sceneSubtitle,
          description: option.sceneDescription,
          tags: option.tags,
          heroIcon: option.icon,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offset = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return SlideTransition(
            position: offset,
            child: FadeTransition(opacity: fade, child: child),
          );
        },
      ),
    );
  }

  InputDecoration _authFieldDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFCFDFC),
      hintStyle: const TextStyle(color: Colors.black45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _authBrand.withValues(alpha: 0.35)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _authBrand, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  Widget _buildDemoAccountPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _authMint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _authBrand.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.key_outlined, size: 18, color: _authBrand),
              SizedBox(width: 8),
              Text(
                '本地可用测试账号',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _authBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '如果你只是想先检查当前进度，直接点下面账号填充即可。',
            style: TextStyle(fontSize: 12, color: Color(0xFF2B4B43), height: 1.5),
          ),
          const SizedBox(height: 12),
          ..._demoAccounts.map(
            (account) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _fillDemoAccount(
                  account['email']!,
                  account['password']!,
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _authBrand.withValues(alpha: 0.10)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account['label']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              account['email']!,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                            Text(
                              account['password']!,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward, size: 18, color: _authBrand),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFDFC),
        surfaceTintColor: Colors.transparent,
        title: const Text('登录'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDemoAccountPanel(),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              autofillHints: const [AutofillHints.username, AutofillHints.email],
              decoration: _authFieldDecoration(
                hintText: '邮箱地址',
                prefixIcon: Icons.mail_outline,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              autofillHints: const [AutofillHints.password],
              decoration: _authFieldDecoration(
                hintText: '密码',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _authBrand,
                      foregroundColor: _authText,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('登录'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.pushNamed(context, '/register'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _authBrand,
                      side: const BorderSide(color: _authBrand),
                    ),
                    child: const Text('去注册'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    const brandColor = _authBg;
    const primaryColor = _authBrand;

    return Scaffold(
      body: Row(
        children: [
          // Left side: Brand area (40%)
          Container(
            width: MediaQuery.of(context).size.width * 0.4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [brandColor, primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _authMint.withValues(alpha: 0.55),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 80,
                    color: _authText,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Sparknote',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _authText,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Sparknote - 专为创作者打造的AI灵感库',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: _authText.withValues(alpha: 0.92),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right side: Login form (60%)
          Expanded(
            child: Container(
              color: const Color(0xFFFCFDFC),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.1,
                    vertical: 40,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),

                      // Login form card
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          border: Border.all(color: _authBrand.withValues(alpha: 0.16)),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Text(
                              '欢迎登录',
                              style:
                                  Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 20),
                            _buildDemoAccountPanel(),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _emailCtrl,
                              autofillHints: const [AutofillHints.username, AutofillHints.email],
                              decoration: _authFieldDecoration(
                                hintText: '邮箱地址',
                                prefixIcon: Icons.mail_outline,
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passwordCtrl,
                              autofillHints: const [AutofillHints.password],
                              decoration: _authFieldDecoration(
                                hintText: '密码',
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),
                              obscureText: _obscurePassword,
                            ),
                            const SizedBox(height: 24),
                            if (_error != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F1),
                                  border: Border.all(color: Colors.red),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                   _authText),
                                        ),
                                      )
                                    : const Text('登录',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: _authText,
                                        )),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('没有账户？'),
                                TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () => Navigator.pushNamed(
                                          context, '/register'),
                                  child: const Text(
                                    '去注册',
                                    style: TextStyle(color: _authBrand),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Persona cards
                      const Text(
                        '选择您的身份',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          ..._personaOptions.map(
                            (option) => _buildPersonaCard(
                              option: option,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaCard({
    required _PersonaOption option,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => _openImmersionScene(option),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 156,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                option.accent.withValues(alpha: 0.10),
              ],
            ),
            border: Border.all(color: option.accent.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: option.accent.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(option.icon, size: 36, color: option.accent),
              const SizedBox(height: 14),
              Text(
                '#${option.label}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: option.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    return isDesktop ? _buildDesktopLayout() : _buildMobileLayout();
  }
}

class _PersonaOption {
  final String label;
  final Color accent;
  final IconData icon;
  final String sceneTitle;
  final String sceneSubtitle;
  final String sceneDescription;
  final List<String> tags;

  const _PersonaOption({
    required this.label,
    required this.accent,
    required this.icon,
    required this.sceneTitle,
    required this.sceneSubtitle,
    required this.sceneDescription,
    required this.tags,
  });
}
