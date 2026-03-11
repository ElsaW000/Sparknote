import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

class AppState extends ChangeNotifier {
  String? _accessToken;
  Map<String, dynamic>? _userInfo;
  List<dynamic> _notes = [];
  bool _loading = false;
  String? _error;

  // Getters
  String? get accessToken => _accessToken;
  Map<String, dynamic>? get userInfo => _userInfo;
  List<dynamic> get notes => _notes;
  bool get loading => _loading;
  String? get error => _error;

  // 初始化状态
  Future<void> initialize() async {
    await _loadToken();
    if (_accessToken != null) {
      await fetchUserInfo();
      await fetchNotes();
    }
  }

  // 加载令牌
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    notifyListeners();
  }

  // 保存令牌
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    _accessToken = token;
    notifyListeners();
  }

  // 清除令牌
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    _accessToken = null;
    _userInfo = null;
    _notes = [];
    notifyListeners();
  }

  // 获取用户信息
  Future<void> fetchUserInfo() async {
    if (_accessToken == null) return;

    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final r = await http.get(
        Uri.parse('$backendUrl/auth/me'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (r.statusCode == 200) {
        _userInfo = json.decode(r.body);
      } else {
        _error = '加载用户信息失败：${r.statusCode}';
      }
    } catch (e) {
      _error = '网络请求失败：$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // 获取笔记列表
  Future<void> fetchNotes() async {
    if (_accessToken == null) return;

    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final r = await http.get(
        Uri.parse('$backendUrl/notes'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (r.statusCode == 200) {
        _notes = json.decode(r.body) as List<dynamic>;
      } else {
        _error = '加载笔记失败：${r.statusCode}';
      }
    } catch (e) {
      _error = '网络请求失败：$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // 创建笔记
  Future<bool> createNote(Map<String, dynamic> noteData) async {
    if (_accessToken == null) return false;

    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final r = await http.post(
        Uri.parse('$backendUrl/notes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: json.encode(noteData),
      );

      if (r.statusCode == 201) {
        await fetchNotes();
        return true;
      } else {
        _error = '创建笔记失败：${r.statusCode}';
        return false;
      }
    } catch (e) {
      _error = '网络请求失败：$e';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // 更新笔记
  Future<bool> updateNote(int noteId, Map<String, dynamic> noteData) async {
    if (_accessToken == null) return false;

    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final r = await http.patch(
        Uri.parse('$backendUrl/notes/$noteId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: json.encode(noteData),
      );

      if (r.statusCode == 200) {
        await fetchNotes();
        return true;
      } else {
        _error = '更新笔记失败：${r.statusCode}';
        return false;
      }
    } catch (e) {
      _error = '网络请求失败：$e';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // 删除笔记
  Future<bool> deleteNote(int noteId) async {
    if (_accessToken == null) return false;

    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final r = await http.delete(
        Uri.parse('$backendUrl/notes/$noteId'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (r.statusCode == 200) {
        await fetchNotes();
        return true;
      } else {
        _error = '删除笔记失败：${r.statusCode}';
        return false;
      }
    } catch (e) {
      _error = '网络请求失败：$e';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
