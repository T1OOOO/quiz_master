import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';

class ApiService {
  // Use localhost for Web, 10.0.2.2 for Android Emulator
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080/api';
    return 'http://10.0.2.2:8080/api';
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> setToken(String token, String username, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('username', username);
    await prefs.setString('role', role);
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setToken(data['token'], data['username'], data['role'] ?? 'user');
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  }

  Future<List<dynamic>> getQuizzes() async {
    final response = await http.get(Uri.parse('$baseUrl/quizzes'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load quizzes');
  }

  Future<Map<String, dynamic>> getQuiz(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/quizzes/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load quiz');
  }

  Future<Map<String, dynamic>> checkAnswer(String quizId, String qId, int answerIdx) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quizzes/$quizId/check'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'question_id': qId,
        'answer_index': answerIdx,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to check answer');
  }
}
