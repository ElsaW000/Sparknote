import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? _userInfo;
  Map<String, dynamic>? _subscriptionInfo;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _fetchSubscriptionInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null || token.isEmpty) {
        setState(() {
          _error = '登录状态已失效';
          _loading = false;
        });
        return;
      }

      final r = await http.get(
        Uri.parse('$backendUrl/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (r.statusCode == 200) {
        final userInfo = json.decode(r.body);
        setState(() => _userInfo = userInfo);
      } else {
        setState(() => _error = '加载用户信息失败：${r.statusCode}');
      }
    } catch (e) {
      setState(() => _error = '网络请求失败：$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchSubscriptionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null || token.isEmpty) return;

      final r = await http.get(
        Uri.parse('$backendUrl/me/subscription'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (r.statusCode == 200) {
        final subscriptionInfo = json.decode(r.body);
        setState(() => _subscriptionInfo = subscriptionInfo);
      }
    } catch (e) {
      // 订阅信息获取失败不影响页面显示
      print('获取订阅信息失败：$e');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    
    // 导航到登录页面
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 用户信息
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '用户信息',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            if (_userInfo != null) ...[
                              ListTile(
                                leading: const Icon(Icons.email),
                                title: const Text('邮箱'),
                                subtitle: Text(_userInfo!['email'] ?? '未知'),
                              ),
                              ListTile(
                                leading: const Icon(Icons.person),
                                title: const Text('身份'),
                                subtitle: Text(_userInfo!['identity'] ?? '未设置'),
                              ),
                              ListTile(
                                leading: const Icon(Icons.account_circle),
                                title: const Text('用户ID'),
                                subtitle: Text(_userInfo!['id'].toString()),
                              ),
                              ListTile(
                                leading: const Icon(Icons.timer),
                                title: const Text('注册时间'),
                                subtitle: Text(_userInfo!['created_at'] ?? '未知'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 订阅信息
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '订阅信息',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            if (_subscriptionInfo != null) ...[
                              ListTile(
                                leading: const Icon(Icons.subscriptions),
                                title: const Text('订阅计划'),
                                subtitle: Text(_subscriptionInfo!['plan'] ?? '未知'),
                              ),
                              ListTile(
                                leading: const Icon(Icons.check_circle),
                                title: const Text('状态'),
                                subtitle: Text(_subscriptionInfo!['status'] ?? '未知'),
                              ),
                              if (_subscriptionInfo!['expire_at'] != null)
                                ListTile(
                                  leading: const Icon(Icons.calendar_today),
                                  title: const Text('到期时间'),
                                  subtitle: Text(_subscriptionInfo!['expire_at']),
                                ),
                            ] else {
                              const Text('无法获取订阅信息'),
                            },
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 其他设置
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '其他设置',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.language),
                              title: const Text('语言'),
                              subtitle: const Text('中文'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // 语言设置
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('语言设置功能开发中')),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.notifications),
                              title: const Text('通知'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // 通知设置
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('通知设置功能开发中')),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.security),
                              title: const Text('隐私设置'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // 隐私设置
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('隐私设置功能开发中')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 退出登录按钮
                    ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('退出登录'),
                    ),
                    const SizedBox(height: 16),

                    // 版本信息
                    Center(
                      child: Text(
                        'Sparknote v1.0.0',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
    );
  }
}
