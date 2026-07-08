import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class ApiClient {
  final String _baseUrl = Constants.baseUrl;
  final String _apiKey = Constants.apiKey;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-API-Key': _apiKey,
      };

  Future<Map<String, dynamic>> sendMessage(
    String message, {
    String? conversationId,
  }) async {
    final body = <String, dynamic>{'message': message};
    if (conversationId != null) {
      body['conversation_id'] = conversationId;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/chat'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed: ${response.statusCode} ${response.body}');
  }
}