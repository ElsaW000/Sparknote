import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _captchaAnswerCtrl = TextEditingController();

  bool _loading = false;
  bool _captchaLoading = false;
  String? _error;
  String? _captchaId;
  String? _captchaQuestion;

  @override
  void initState() {
    super.initState();
    _loadCaptcha();
  }

  Future<void> _loadCaptcha() async {
    setState(() {
      _captchaLoading = true;
      _captchaId = null;
      _captchaQuestion = null;
    });
    try {
      final resp = await http.get(Uri.parse('$backendUrl/auth/captcha'));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        setState(() {
          _captchaId = data['captcha_id']?.toString();
          _captchaQuestion = data['question']?.toString();
        });
      } else {
        setState(() {
          _error = '验证码加载失败：${resp.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = '验证码请求失败：$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _captchaLoading = false;
        });
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
        setState(() => _error = '请完整填写邮箱和密码');
        return;
      }
      if (password != confirmPassword) {
        setState(() => _error = '两次输入的密码不一致');
        return;
      }
      if ((_captchaId ?? '').isEmpty || (_captchaQuestion ?? '').isEmpty) {
        setState(() => _error = '验证码尚未就绪，请先刷新验证码');
        return;
      }
      if (captchaAnswer.isEmpty) {
        setState(() => _error = '请先填写验证码答案');
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
        final detail = _readErrorDetail(registerResp.body);
        setState(() => _error = '注册失败：$detail');
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
        setState(() => _error = '注册成功，但自动登录失败');
        return;
      }

      final data = json.decode(loginResp.body) as Map<String, dynamic>;
      final token = data['access_token'] as String?;
      if (token == null || token.isEmpty) {
        setState(() => _error = '登录响应异常：缺少 token');
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/notes', (route) => false);
    } catch (e) {
      // provide a clearer hint when the network request fails entirely
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
    return '请稍后重试';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _captchaAnswerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: '邮箱'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: '密码'),
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordCtrl,
              decoration: const InputDecoration(labelText: '确认密码'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _captchaLoading
                        ? '验证码加载中...'
                        : (_captchaQuestion ?? '验证码不可用，请刷新'),
                  ),
                ),
                IconButton(
                  onPressed: _captchaLoading ? null : _loadCaptcha,
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新验证码',
                ),
              ],
            ),
            TextField(
              controller: _captchaAnswerCtrl,
              decoration: const InputDecoration(labelText: '验证码答案'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('注册并进入'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : () => Navigator.pop(context),
              child: const Text('已有账号？返回登录'),
            ),
          ],
        ),
      ),
    );
  }
}
