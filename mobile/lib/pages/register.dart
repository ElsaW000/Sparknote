import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const Color _brand = Color(0xFF2D6A4F);
  static const Color _brandDark = Color(0xFF1A3C34);
  static const Color _canvas = Color(0xFFF7FAF8);
  static const Color _panel = Color(0xFFD8E2DC);
  static const Color _paper = Color(0xFFFCFDFC);
  static const Color _ink = Color(0xFF263238);
  static const Color _muted = Color(0xFF60716F);
  static const Color _line = Color(0xFFC6D6CD);

  static final RegExp _emailPattern =
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _captchaAnswerCtrl = TextEditingController();

  bool _loading = false;
  bool _captchaLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;
  String? _captchaId;
  String? _captchaQuestion;

  @override
  void initState() {
    super.initState();
    _loadCaptcha();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _captchaAnswerCtrl.dispose();
    super.dispose();
  }

  String _decodeResponse(http.Response response) {
    return utf8.decode(response.bodyBytes);
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
      fillColor: _paper,
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
        borderSide: const BorderSide(color: _brand, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    );
  }

  Future<void> _loadCaptcha() async {
    setState(() {
      _captchaLoading = true;
      _captchaId = null;
      _captchaQuestion = null;
    });
    try {
      final resp = await http.get(Uri.parse('$backendUrl/auth/captcha'));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = json.decode(_decodeResponse(resp)) as Map<String, dynamic>;
        setState(() {
          _captchaId = data['captcha_id']?.toString();
          _captchaQuestion = data['question']?.toString();
        });
      } else {
        setState(() => _error = '\u9a8c\u8bc1\u7801\u52a0\u8f7d\u5931\u8d25\uff1a${resp.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '\u9a8c\u8bc1\u7801\u8bf7\u6c42\u5931\u8d25\uff1a$e');
    } finally {
      if (mounted) {
        setState(() => _captchaLoading = false);
      }
    }
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;
      final confirmPassword = _confirmPasswordCtrl.text;
      final captchaAnswer = _captchaAnswerCtrl.text.trim();

      if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
        setState(() => _error = '\u8bf7\u5b8c\u6574\u586b\u5199\u90ae\u7bb1\u548c\u5bc6\u7801');
        return;
      }
      if (!_emailPattern.hasMatch(email)) {
        setState(() => _error = '\u8bf7\u8f93\u5165\u6709\u6548\u7684\u90ae\u7bb1\u5730\u5740');
        return;
      }
      if (password != confirmPassword) {
        setState(() => _error = '\u4e24\u6b21\u8f93\u5165\u7684\u5bc6\u7801\u4e0d\u4e00\u81f4');
        return;
      }
      if (password.length < 6) {
        setState(() => _error = '\u5bc6\u7801\u81f3\u5c11\u9700\u8981 6 \u4f4d');
        return;
      }
      if ((_captchaId ?? '').isEmpty || (_captchaQuestion ?? '').isEmpty) {
        setState(() => _error = '\u9a8c\u8bc1\u7801\u5c1a\u672a\u5c31\u7eea\uff0c\u8bf7\u5148\u5237\u65b0\u9a8c\u8bc1\u7801');
        return;
      }
      if (captchaAnswer.isEmpty) {
        setState(() => _error = '\u8bf7\u586b\u5199\u9a8c\u8bc1\u7801\u7b54\u6848');
        return;
      }

      final registerResp = await http.post(
        Uri.parse('$backendUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'captcha_id': _captchaId,
          'captcha_answer': captchaAnswer,
        }),
      );
      if (registerResp.statusCode != 201) {
        final detail = _readErrorDetail(_decodeResponse(registerResp));
        setState(() => _error = '\u6ce8\u518c\u5931\u8d25\uff1a$detail');
        await _loadCaptcha();
        _captchaAnswerCtrl.clear();
        return;
      }

      final loginResp = await http.post(
        Uri.parse('$backendUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      if (loginResp.statusCode != 200) {
        setState(() => _error = '\u6ce8\u518c\u6210\u529f\uff0c\u4f46\u81ea\u52a8\u767b\u5f55\u5931\u8d25');
        return;
      }

      final data = json.decode(_decodeResponse(loginResp)) as Map<String, dynamic>;
      final token = data['access_token'] as String?;
      if (token == null || token.isEmpty) {
        setState(() => _error = '\u767b\u5f55\u54cd\u5e94\u5f02\u5e38\uff1a\u7f3a\u5c11 token');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/notes', (route) => false);
    } catch (e) {
      if (e is http.ClientException) {
        setState(() => _error = '\u65e0\u6cd5\u8fde\u63a5\u5230\u670d\u52a1\u5668\uff0c\u8bf7\u68c0\u67e5 BACKEND_URL \u548c\u540e\u7aef\u662f\u5426\u5728\u8fd0\u884c');
      } else {
        setState(() => _error = '\u8bf7\u6c42\u5f02\u5e38\uff1a$e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _readErrorDetail(String rawBody) {
    try {
      final body = json.decode(rawBody);
      if (body is Map<String, dynamic>) {
        final detail = body['detail']?.toString();
        if (detail != null && detail.isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {}
    return '\u8bf7\u7a0d\u540e\u91cd\u8bd5';
  }

  Widget _buildCaptchaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _brand.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: _brandDark, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _captchaLoading
                  ? '\u6b63\u5728\u52a0\u8f7d\u9a8c\u8bc1\u7801...'
                  : (_captchaQuestion ??
                      '\u9a8c\u8bc1\u7801\u4e0d\u53ef\u7528\uff0c\u8bf7\u70b9\u51fb\u5237\u65b0'),
              style: const TextStyle(fontSize: 14, color: _ink, height: 1.6),
            ),
          ),
          IconButton(
            onPressed: _captchaLoading ? null : _loadCaptcha,
            icon: const Icon(Icons.refresh),
            tooltip: '\u5237\u65b0\u9a8c\u8bc1\u7801',
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterHelperPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _brand.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 18, color: _brandDark),
              SizedBox(width: 8),
              Text(
                '\u521b\u5efa\u4f60\u7684 Sparknote \u8d26\u53f7',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _brandDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '\u6ce8\u518c\u540e\u4f1a\u81ea\u52a8\u8fdb\u5165\u7075\u611f\u5de5\u4f5c\u533a\u3002\u53f3\u4fa7\u8868\u5355\u53ea\u662f\u767b\u5f55\u9875\u7684\u6ce8\u518c\u7248\uff0c\u4fdd\u6301\u540c\u4e00\u5957\u89c6\u89c9\u9aa8\u67b6\u3002',
            style: TextStyle(fontSize: 12, color: Color(0xFF2B4B43), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({required bool compact}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brand.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(compact ? 24 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u6b22\u8fce\u6ce8\u518c',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          _buildRegisterHelperPanel(),
          const SizedBox(height: 24),
          TextField(
            controller: _emailCtrl,
            decoration: _fieldDecoration(
              label: '\u90ae\u7bb1\u5730\u5740',
              hint: 'name@example.com',
              prefixIcon: const Icon(Icons.mail_outline),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordCtrl,
            decoration: _fieldDecoration(
              label: '\u5bc6\u7801',
              hint: '\u81f3\u5c11 6 \u4f4d',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              ),
            ),
            obscureText: _obscurePassword,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirmPasswordCtrl,
            decoration: _fieldDecoration(
              label: '\u786e\u8ba4\u5bc6\u7801',
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              suffixIcon: IconButton(
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            obscureText: _obscureConfirmPassword,
          ),
          const SizedBox(height: 18),
          _buildCaptchaCard(),
          const SizedBox(height: 14),
          TextField(
            controller: _captchaAnswerCtrl,
            decoration: _fieldDecoration(
              label: '\u9a8c\u8bc1\u7801\u7b54\u6848',
              hint: '\u8f93\u5165\u4e0a\u65b9\u7b97\u5f0f\u7ed3\u679c',
              prefixIcon: const Icon(Icons.calculate_outlined),
            ),
            keyboardType: TextInputType.number,
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
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '\u6ce8\u518c\u5e76\u8fdb\u5165',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('\u5df2\u6709\u8d26\u53f7\uff1f'),
              TextButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                child: const Text(
                  '\u8fd4\u56de\u767b\u5f55',
                  style: TextStyle(color: _brand),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandPanel() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandDark, _brand],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _panel.withValues(alpha: 0.70),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.edit, size: 80, color: Colors.white),
          ),
          const SizedBox(height: 32),
          const Text(
            'Sparknote',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Sparknote - \u4e13\u4e3a\u521b\u4f5c\u8005\u6253\u9020\u7684AI\u7075\u611f\u5e93',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.92),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _canvas,
        surfaceTintColor: Colors.transparent,
        title: const Text('\u6ce8\u518c'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(child: _buildFormCard(compact: true)),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          _buildBrandPanel(),
          Expanded(
            child: Container(
              color: _paper,
              child: SafeArea(
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
                        _buildFormCard(compact: false),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1200;
    return isDesktop ? _buildDesktopLayout() : _buildMobileLayout();
  }
}
