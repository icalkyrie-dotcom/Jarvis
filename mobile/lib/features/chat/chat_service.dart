import '../../../core/api_client.dart';

class ChatService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> sendMessage(
    String message, {
    String? conversationId,
  }) async {
    return await _client.sendMessage(
      message,
      conversationId: conversationId,
    );
  }
}