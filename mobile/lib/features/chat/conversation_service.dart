import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';

class ConversationItem {
  final String id;
  final String title;
  final String updatedAt;

  ConversationItem({
    required this.id,
    required this.title,
    required this.updatedAt,
  });

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    return ConversationItem(
      id: json['id'],
      title: json['title'],
      updatedAt: json['updated_at'],
    );
  }
}

class ConversationService {
  final String _baseUrl = Constants.baseUrl;
  final String _apiKey = Constants.apiKey;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-API-Key': _apiKey,
      };

  Future<List<ConversationItem>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/conversations'),
        headers: _headers,
      );
      debugPrint('📡 GET /conversations status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['conversations'] as List)
            .map((c) => ConversationItem.fromJson(c))
            .toList();
      }
      throw Exception('Failed to load conversations: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Full error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getConversationDetail(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/conversations/$id'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load conversation');
  }

  Future<void> deleteConversation(String id) async {
    await http.delete(
      Uri.parse('$_baseUrl/conversations/$id'),
      headers: _headers,
    );
  }

  Future<void> renameConversation(String id, String title) async {
    await http.patch(
      Uri.parse('$_baseUrl/conversations/$id/title'),
      headers: _headers,
      body: jsonEncode({'title': title}),
    );
  }
}